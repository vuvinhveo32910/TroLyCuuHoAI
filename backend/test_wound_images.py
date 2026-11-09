import base64
import io
import json
from pathlib import Path
import sys
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent / 'medgemma'))
from wound_images import WoundImageService, ImageAnalysisError, CLASSES, image_context, image_reference_query, image_reference_queries
from server import ChatService, ThreadingHTTPServer, make_handler
from reference_relevance import is_wound_care_question, reference_scope
from knowledge_search import demo_reference_order


def image_payload():
    output = io.BytesIO()
    Image.new('RGB', (40, 30), 'white').save(output, format='PNG')
    return {'image_base64': base64.b64encode(output.getvalue()).decode()}


def detection(name='tray_xuoc', confidence=0.9):
    return {'class_id': list(CLASSES).index(name), 'class_name': name,
            'confidence': confidence, 'box': [1, 2, 35, 28]}


class Detector:
    def __init__(self, predictions):
        self.predictions, self.calls = predictions, 0

    def predict(self, image):
        self.calls += 1
        return self.predictions


class Runner:
    state, error, load_seconds = 'ready', '', 0

    def __init__(self):
        self.calls = []

    def answer(self, *args):
        self.calls.append(args)
        return {'answer': 'Ảnh chỉ gợi ý tổn thương. Bạn bị ở đâu và từ khi nào?',
                'truncated': False, 'generated_tokens': 15, 'generation_seconds': 0.1}


class ImageTests(unittest.TestCase):
    def test_user_reported_flags_are_preserved_and_take_priority_over_image_class(self):
        images = WoundImageService('unused', detector=Detector([]))
        record = images.analyze({**image_payload(), 'observations': {
            'heavy_bleeding': True, 'foreign_body': True, 'infection_signs': False}})
        self.assertIsNone(record['primary'])
        self.assertEqual(record['observations'], {'heavy_bleeding': True, 'foreign_body': True})
        queries = image_reference_queries(record, 'Giải thích ảnh', initial=True)
        self.assertEqual(queries, ['Vết thương đang chảy máu nhiều', 'Vết thương có dị vật cắm vào'])
        self.assertIn('heavy_bleeding', image_context(record, followup=True))
        for invalid in ({'heavy_bleeding': 'true'}, {'class_name': True}, [], None):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ImageAnalysisError):
                    images.analyze({**image_payload(), 'observations': invalid})

    def test_bmp_image_is_supported_for_clipboard_and_file_picker(self):
        stream = io.BytesIO()
        Image.new('RGB', (24, 20), 'white').save(stream, format='BMP')
        images = WoundImageService('unused', detector=Detector([]))
        record = images.analyze({'image_base64': base64.b64encode(stream.getvalue()).decode()})
        self.assertEqual((record['image_width'], record['image_height']), (24, 20))

    def test_all_four_model_classes_and_filename_does_not_choose_a_class(self):
        for name, (label, topic, _) in CLASSES.items():
            with self.subTest(name=name):
                images = WoundImageService('unused', detector=Detector([detection(name)]))
                result = images.analyze({**image_payload(), 'filename': 'bong_burn.jpg'})
                self.assertEqual(result['primary']['class_name'], name)
                self.assertEqual(result['primary']['label'], label)
                self.assertEqual(result['primary']['topic_id'], topic)
                self.assertEqual(result['device'], 'cpu')
                self.assertEqual(images.get(result['analysis_id']), result)

    def test_uncertain_multiple_and_no_detection_never_default_to_abrasion(self):
        for predictions, status in (([], 'no_detection'), ([detection(confidence=0.3)], 'uncertain'),
                                    ([detection(), detection('bong')], 'multiple')):
            with self.subTest(status=status):
                images = WoundImageService('unused', detector=Detector(predictions))
                result = images.analyze(image_payload())
                self.assertEqual(result['status'], status)
                self.assertIsNone(result['primary'])

    def test_invalid_image_and_oversized_image_are_rejected(self):
        images = WoundImageService('unused', detector=Detector([]))
        for payload in ({'image_base64': 'not base64!'},
                        {'image_base64': base64.b64encode(b'not an image').decode()},
                        {**image_payload(), 'contrast': True},
                        {**image_payload(), 'contrast': float('nan')},
                        {'image_base64': 'A' * (14 * 1024 * 1024)}):
            with self.subTest(payload_type=list(payload)):
                with self.assertRaises(ImageAnalysisError):
                    images.analyze(payload)
        self.assertEqual(images.detector.calls, 0)

    def test_expired_or_forged_analysis_ids_cannot_be_used(self):
        now = [1]
        images = WoundImageService('unused', detector=Detector([]), ttl=2, clock=lambda: now[0])
        record = images.analyze(image_payload())
        now[0] = 4
        for identifier in (record['analysis_id'], 'forged-id-abcdefghijklmnop'):
            with self.assertRaises(ImageAnalysisError) as error:
                images.get(identifier)
            self.assertEqual(error.exception.status, 410)

    def test_burn_context_does_not_assume_thermal_cause(self):
        images = WoundImageService('unused', detector=Detector([detection('bong')]))
        context = image_context(images.analyze(image_payload()))
        self.assertIn('hóa chất', context)
        self.assertIn('điện', context)
        self.assertIn('Hỏi nguyên nhân', context)

    def test_existing_source_is_returned_without_waiting_for_medgemma(self):
        images = WoundImageService('unused', detector=Detector([detection()]))
        record = images.analyze(image_payload())
        runner = Runner()
        service = ChatService(runner=runner, sqlite_path=None, image_analyzer=images)

        class Grounded:
            query = None
            def extract_sources(self, question):
                self.query = question
                return {'route': 'source_grounded', 'answer': 'VERBATIM SOURCE',
                        'generated_tokens': 0, 'generation_seconds': 0, 'evidence_mode': 'extractive',
                        'citations': [{'title': 'PDF', 'pdf_url': '/api/source/test#page=1'}]}
        service.grounded = Grounded()
        payload = {'message': 'Giải thích ảnh', 'image_analysis_id': record['analysis_id'],
                   'image_initial': True, 'class_name': 'bong'}
        reply = service.chat(payload)
        self.assertEqual(reply['route'], 'image_source_grounded')
        self.assertEqual(service.grounded.query, 'Tôi bị trầy xước')
        self.assertEqual(reply['answer'], 'VERBATIM SOURCE')
        self.assertEqual(len(reply['citations']), 1)
        self.assertEqual(reply['generated_tokens'], 0)
        self.assertEqual(service.chat(payload)['route'], 'image_source_grounded')
        self.assertEqual(runner.calls, [])

    def test_model_is_used_only_when_reference_is_missing(self):
        images = WoundImageService('unused', detector=Detector([detection()]))
        record = images.analyze(image_payload())
        runner = Runner()
        service = ChatService(runner=runner, sqlite_path=None, image_analyzer=images)
        payload = {'message': 'Giải thích ảnh', 'image_analysis_id': record['analysis_id'], 'image_initial': True}
        reply = service.chat(payload)
        self.assertEqual(reply['route'], 'image_guidance')
        self.assertEqual(runner.calls[0][3], 'image_guidance')
        self.assertIn('Trầy xước', runner.calls[0][2])
        self.assertEqual(service.chat(payload)['route'], 'cache')
        self.assertEqual(len(runner.calls), 1)

    def test_uncertain_or_burn_photo_asks_details_without_generation(self):
        for predictions in ([], [detection('bong')], [detection(confidence=0.3)],
                            [detection(), detection('bam_tim')]):
            with self.subTest(predictions=predictions):
                images = WoundImageService('unused', detector=Detector(predictions))
                record = images.analyze(image_payload())
                runner = Runner()
                service = ChatService(runner=runner, sqlite_path=None, image_analyzer=images)
                reply = service.chat({'message': 'Giải thích ảnh', 'image_analysis_id': record['analysis_id'], 'image_initial': True})
                self.assertEqual(reply['route'], 'image_clarify')
                self.assertEqual(reply['generated_tokens'], 0)
                self.assertEqual(reply['citations'], [])
                self.assertEqual(runner.calls, [])
                if record['primary']:
                    self.assertIn('hóa chất hay điện', reply['answer'])

    def test_retired_source_does_not_fall_back_to_unverified_generation(self):
        images = WoundImageService('unused', detector=Detector([detection()]))
        record = images.analyze(image_payload())
        runner = Runner()
        service = ChatService(runner=runner, sqlite_path=None, image_analyzer=images)
        class ChangedGrounded:
            def extract_sources(self, query):
                return {'route': 'clarify', 'unavailable_reason': 'source_changed',
                        'answer': 'Tài liệu vừa ngừng sử dụng.', 'citations': [], 'generated_tokens': 0}
        service.grounded = ChangedGrounded()
        reply = service.chat({'message': 'Giải thích ảnh', 'image_analysis_id': record['analysis_id'], 'image_initial': True})
        self.assertEqual(reply['route'], 'image_clarify')
        self.assertEqual(runner.calls, [])

    def test_follow_up_uses_latest_question_instead_of_initial_image_prompt(self):
        images = WoundImageService('unused', detector=Detector([detection()]))
        record = images.analyze(image_payload())
        runner = Runner()
        service = ChatService(runner=runner, sqlite_path=None, image_analyzer=images)
        question = 'tôi muốn biết cách sát trùng vết thương'
        reply = service.chat({'message': question, 'image_analysis_id': record['analysis_id']})
        self.assertEqual(reply['route'], 'image_followup')
        self.assertEqual(runner.calls[0][0], question)
        self.assertEqual(runner.calls[0][3], 'image_followup')
        facts = json.loads(runner.calls[0][2])
        self.assertEqual(facts['prediction']['label'], 'Trầy xước')
        self.assertFalse(facts['confirmed_diagnosis'])
        self.assertNotIn('Hỏi', runner.calls[0][2])
        self.assertEqual(reply['source_review_label'], 'MedGemma trả lời — chưa đối chiếu nguồn')

    def test_related_wound_follow_up_keeps_hint_but_not_unrelated_or_negated_topics(self):
        images = WoundImageService('unused', detector=Detector([detection()]))
        record = images.analyze(image_payload())
        for question in ('vết này rửa thế nào', 'rửa bằng gì?', 'vệ sinh vùng da này như thế nào'):
            with self.subTest(question=question):
                query = image_reference_query(record, question)
                self.assertIn('Tôi bị trầy xước', query)
                self.assertIn(question, query)
        for question in ('tôi bị đau đầu', 'rửa bát thế nào', 'bỏng ngô là gì',
                         'không phải trầy xước, tôi bị bỏng hóa chất', 'tôi không bị trầy xước'):
            with self.subTest(question=question):
                self.assertEqual(image_reference_query(record, question), question)

    def test_social_follow_up_does_not_repeat_image_questions(self):
        images = WoundImageService('unused', detector=Detector([detection()]))
        record = images.analyze(image_payload())
        runner = Runner()
        service = ChatService(runner=runner, sqlite_path=None, image_analyzer=images)
        reply = service.chat({'message': 'cảm ơn bạn', 'image_analysis_id': record['analysis_id']})
        self.assertEqual(reply['route'], 'conversation')
        self.assertEqual(runner.calls, [])

    def test_wound_cleaning_question_maps_to_cleaning_sources_not_generic_injury_report(self):
        question = 'tôi muốn biết cách sát trùng vết thương'
        self.assertTrue(is_wound_care_question(question))
        self.assertTrue({'cut', 'graze'} <= reference_scope(question)[0])
        entries = [{'slug': slug} for slug in
                   ('cut-referral', 'small-wound-dressing', 'small-wound-cleaning',
                    'thermal-burn-cooling', 'burn-medical-referral', 'embedded-foreign-body')]
        self.assertEqual([item['slug'] for item in demo_reference_order(entries, question)],
                         ['small-wound-cleaning', 'small-wound-dressing'])
        self.assertEqual(demo_reference_order(entries, 'rửa vết bỏng nhiệt')[0]['slug'], 'thermal-burn-cooling')
        self.assertEqual(demo_reference_order(entries, 'rửa vết thương có dị vật')[0]['slug'], 'embedded-foreign-body')
        self.assertFalse(is_wound_care_question('sát trùng vết thương lòng'))


class ImageApiTests(unittest.TestCase):
    def setUp(self):
        self.detector = Detector([detection()])
        self.runner = Runner()
        self.service = ChatService(runner=self.runner, sqlite_path=None,
                                  image_analyzer=WoundImageService('unused', detector=self.detector))
        self.server = ThreadingHTTPServer(('127.0.0.1', 0), make_handler(self.service, allow_local_web=True))
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base = f'http://127.0.0.1:{self.server.server_port}'

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def request(self, path, data=None, method='POST', **headers):
        request = Request(self.base + path, method=method,
                          data=json.dumps(data).encode() if data is not None else None,
                          headers={'Origin': 'http://localhost:8080', 'Content-Type': 'application/json', **headers})
        try:
            return urlopen(request, timeout=5)
        except HTTPError as error:
            return error

    def test_http_image_to_medgemma_handoff_and_cors(self):
        with self.request('/api/analyze-image', method='OPTIONS',
                          **{'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'Content-Type'}) as response:
            self.assertEqual(response.status, 204)
        with self.request('/api/analyze-image', image_payload()) as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers['Access-Control-Allow-Origin'], 'http://localhost:8080')
            record = json.load(response)
        with self.request('/api/chat', {'message': 'Giải thích ảnh', 'image_initial': True,
                                        'image_analysis_id': record['analysis_id']}) as response:
            reply = json.load(response)
            self.assertEqual(response.status, 200)
        self.assertEqual(reply['route'], 'image_guidance')
        self.assertEqual(len(self.runner.calls), 1)
        self.assertEqual(self.detector.calls, 1)
        with self.request('/api/chat', {'message': 'giải thích', 'image_analysis_id': 'forged-abcdefghijklmnop'}) as response:
            self.assertEqual(response.status, 410)
        with self.request('/api/analyze-image', {'image_base64': 'bad!'}) as response:
            self.assertEqual(response.status, 400)


if __name__ == '__main__':
    unittest.main()
