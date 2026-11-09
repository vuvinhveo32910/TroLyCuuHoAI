from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parent / 'medgemma'))
from conversation_shortcuts import social_reply
from server import ChatService


class RecordingRunner:
    state, error, load_seconds = 'ready', '', 0

    def __init__(self):
        self.calls = []

    def answer(self, *args):
        self.calls.append(args)
        return {'answer': 'Model reply', 'truncated': False, 'generated_tokens': 3}


class ConversationTests(unittest.TestCase):
    def test_complete_social_statements_are_quick_and_honestly_labelled(self):
        for question in ('hello', '  XIN CHÀO!!!  ', 'cảm ơn bạn', 'Tạm biệt.',
                         'alo tôi muốn đi chơi', 'Alo, tôi muốn đi chơi!',
                         'toi muon di choi', 'Mình định đi dạo cuối tuần'):
            with self.subTest(question=question):
                runner = RecordingRunner()
                runner.state = 'error'
                service = ChatService(runner=runner, sqlite_path=None, preload_enabled=False)
                reply = service.chat({'message': question})
                self.assertEqual(reply['route'], 'conversation')
                self.assertEqual(reply['generated_tokens'], 0)
                self.assertEqual(reply['evidence_mode'], 'application_help')
                self.assertEqual(reply['source_review_label'], 'Phản hồi nhanh của ứng dụng')
                self.assertEqual(reply['citations'], [])
                self.assertNotIn('fallback_notice', reply)
                self.assertEqual(runner.calls, [])

    def test_medical_context_negation_and_extra_words_never_match(self):
        for question in ('hello tôi bị đau đầu', 'alo, tay tôi bị bỏng',
                         'alo tôi muốn đi chơi nhưng đang đau bụng',
                         'tôi muốn đi chơi sau phẫu thuật được không',
                         'tôi muốn đi chơi nhưng tôi bị điện giật',
                         'tôi không muốn đi chơi', 'tôi muốn đi chơi được không?',
                         'hello 🩸', 'bỏng ngô', 'bỏn tay', 'hi 115',
                         '"tôi muốn đi chơi" nghĩa là gì', 'cảm ơn, tôi bị khó thở'):
            with self.subTest(question=question):
                self.assertIsNone(social_reply(question))

    def test_medical_request_still_reaches_original_model_route(self):
        runner = RecordingRunner()
        service = ChatService(runner=runner, sqlite_path=None, preload_enabled=False)
        reply = service.chat({'message': 'alo tôi muốn đi chơi nhưng đang đau bụng'})
        self.assertEqual(reply['route'], 'model_fallback')
        self.assertEqual(len(runner.calls), 1)
        self.assertEqual(runner.calls[0][0], 'alo tôi muốn đi chơi nhưng đang đau bụng')

    def test_model_experiment_keeps_using_the_model(self):
        runner = RecordingRunner()
        service = ChatService(runner=runner, sqlite_path=None, preload_enabled=False)
        reply = service.chat({'message': 'hello', 'mode': 'experiment'})
        self.assertEqual(reply['route'], 'model_experiment')
        self.assertEqual(len(runner.calls), 1)

    def test_follow_up_or_document_selection_cannot_be_shortcut(self):
        for extra in ({'history': [{'question': 'đau đầu', 'answer': 'previous reply'}]},
                      {'guide_id': 1}):
            with self.subTest(extra=extra):
                runner = RecordingRunner()
                service = ChatService(runner=runner, sqlite_path=None, preload_enabled=False)
                reply = service.chat({'message': 'hello', **extra})
                self.assertNotEqual(reply['route'], 'conversation')
                self.assertEqual(len(runner.calls), 1)


if __name__ == '__main__':
    unittest.main()
