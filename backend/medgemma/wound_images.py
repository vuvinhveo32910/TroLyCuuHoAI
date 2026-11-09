"""Local YOLO image predictions and short-lived, server-owned chat context."""
import base64
from collections import OrderedDict
import io
import json
import math
import os
import re
from pathlib import Path
import secrets
import threading
import time
import warnings
from knowledge_search import fold, query_topics
from reference_relevance import reference_scope, is_wound_care_question

MAX_IMAGE_BYTES = 10 * 1024 * 1024
MAX_IMAGE_PIXELS = 16_000_000
CLASSES = {
    'tray_xuoc': ('Trầy xước', 'abrasion', 'Tôi bị trầy xước'),
    'vet_cat_rach': ('Vết cắt, rách', 'cut_laceration', 'Tôi bị vết cắt rách'),
    'bong': ('Bỏng', 'burn', ''),
    'bam_tim': ('Bầm', 'bruise', 'Tôi bị bầm tím'),
}
OBSERVATIONS = {
    'heavy_bleeding': ('chảy máu nhiều/liên tục', 'Vết thương đang chảy máu nhiều'),
    'foreign_body': ('có dị vật cắm vào vết thương', 'Vết thương có dị vật cắm vào'),
    'infection_signs': ('có mủ hoặc sưng đỏ tấy', 'Vết thương có dấu hiệu nhiễm trùng'),
}


class ImageAnalysisError(Exception):
    def __init__(self, message, status=400):
        super().__init__(message)
        self.status = status


def read_image(payload):
    from PIL import Image, ImageEnhance, ImageOps, UnidentifiedImageError
    encoded = payload.get('image_base64')
    if not isinstance(encoded, str) or not encoded:
        raise ImageAnalysisError('Chưa có dữ liệu ảnh.')
    if len(encoded) > 4 * ((MAX_IMAGE_BYTES + 2) // 3):
        raise ImageAnalysisError('Ảnh vượt quá 10 MB.', 413)
    try:
        raw = base64.b64decode(encoded, validate=True)
    except (ValueError, base64.binascii.Error) as exc:
        raise ImageAnalysisError('Dữ liệu ảnh không hợp lệ.') from exc
    if len(raw) > MAX_IMAGE_BYTES:
        raise ImageAnalysisError('Ảnh vượt quá 10 MB.', 413)
    contrast = payload.get('contrast', 1.0)
    if type(contrast) not in (int, float) or not math.isfinite(contrast) or not 0.5 <= contrast <= 3:
        raise ImageAnalysisError('Độ tương phản phải từ 0,5 đến 3.')
    try:
        with warnings.catch_warnings():
            warnings.simplefilter('error', Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(raw)) as original:
                if original.format not in {'JPEG', 'PNG', 'WEBP', 'BMP'}:
                    raise ImageAnalysisError('Chỉ hỗ trợ ảnh JPG, PNG, WEBP hoặc BMP.', 415)
                if original.width * original.height > MAX_IMAGE_PIXELS:
                    raise ImageAnalysisError('Ảnh quá lớn. Hãy giảm xuống dưới 16 triệu điểm ảnh.', 413)
                image = ImageOps.exif_transpose(original).convert('RGB')
        if contrast != 1:
            image = ImageEnhance.Contrast(image).enhance(contrast)
        return image
    except ImageAnalysisError:
        raise
    # Ultralytics can try an optional HEIF plugin for unrecognized input.
    except (UnidentifiedImageError, OSError, ValueError, ImportError, Image.DecompressionBombError, Image.DecompressionBombWarning) as exc:
        raise ImageAnalysisError('Không đọc được ảnh. Hãy chọn lại ảnh JPG, PNG hoặc WEBP còn nguyên vẹn.', 415) from exc


class YoloWoundDetector:
    def __init__(self, model_path):
        self.path = Path(model_path)
        self.model = None

    def predict(self, image):
        if self.model is None:
            if not self.path.is_file():
                raise ImageAnalysisError('Không tìm thấy best.pt. Kiểm tra cấu hình model ảnh.', 503)
            os.environ.setdefault('YOLO_CONFIG_DIR', str(Path(__file__).resolve().parents[1] / 'runtime' / 'ultralytics'))
            os.environ.setdefault('YOLO_OFFLINE', 'true')
            os.environ.setdefault('YOLO_AUTOINSTALL', 'false')
            from ultralytics import YOLO
            model = YOLO(str(self.path), task='detect')
            if set(model.names.values()) != set(CLASSES):
                raise ImageAnalysisError('best.pt không chứa đúng bốn class tổn thương của dự án.', 503)
            self.model = model
        result = self.model.predict(source=image, device='cpu', conf=0.25,
                                    imgsz=640, max_det=20, verbose=False, save=False)[0]
        return [{'class_id': int(box.cls.item()),
                 'class_name': self.model.names[int(box.cls.item())],
                 'confidence': float(box.conf.item()),
                 'box': box.xyxy[0].tolist()} for box in result.boxes]


class WoundImageService:
    def __init__(self, model_path, detector=None, ttl=1800, clock=time.monotonic):
        self.detector = detector if detector is not None else YoloWoundDetector(model_path)
        self.ttl, self.clock = ttl, clock
        self.records = OrderedDict()
        self.records_lock = threading.Lock()
        self.inference_lock = threading.Lock()

    def analyze(self, payload):
        if not self.inference_lock.acquire(blocking=False):
            raise ImageAnalysisError('Đang phân tích ảnh khác. Hãy đợi rồi thử lại.', 429)
        started = time.perf_counter()
        try:
            observations = payload.get('observations', {})
            if (not isinstance(observations, dict) or set(observations) - set(OBSERVATIONS)
                    or any(type(value) is not bool for value in observations.values())):
                raise ImageAnalysisError('Dấu hiệu được chọn phải là các giá trị đúng/sai hợp lệ.')
            observations = {key: True for key, value in observations.items() if value}
            image = read_image(payload)
            try:
                predictions = self.detector.predict(image)
            except ImageAnalysisError:
                raise
            except ImportError as exc:
                raise ImageAnalysisError('Chưa cài thư viện nhận diện ảnh. Cài backend/requirements.txt rồi khởi động lại API.', 503) from exc
            except Exception as exc:
                raise ImageAnalysisError('Chưa chạy được model ảnh. Kiểm tra best.pt và nhật ký API.', 503) from exc
            detections = []
            for prediction in predictions:
                name, score = prediction.get('class_name'), prediction.get('confidence')
                box = prediction.get('box')
                if (name not in CLASSES or type(score) not in (int, float)
                        or not math.isfinite(score) or not 0.25 <= score <= 1
                        or not isinstance(box, (list, tuple)) or len(box) != 4
                        or any(type(x) not in (int, float) or not math.isfinite(x) for x in box)):
                    continue
                label, topic, _ = CLASSES[name]
                detections.append({'class_id': int(prediction['class_id']), 'class_name': name,
                                   'label': label, 'topic_id': topic, 'confidence': round(score, 4),
                                   'box': [max(0, min(float(x), image.width if i % 2 == 0 else image.height))
                                           for i, x in enumerate(box)]})
            detections.sort(key=lambda item: item['confidence'], reverse=True)
            detections = detections[:20]
            strong = [item for item in detections if item['confidence'] >= 0.5]
            distinct = {item['class_name'] for item in strong}
            status = 'detected' if len(distinct) == 1 else ('multiple' if distinct else 'uncertain')
            if not detections:
                status = 'no_detection'
            primary = strong[0] if status == 'detected' else None
            record = {'analysis_id': secrets.token_urlsafe(24), 'status': status,
                      'detections': detections, 'primary': primary,
                      'image_width': image.width, 'image_height': image.height,
                      'device': 'cpu', 'observations': observations,
                      'analysis_seconds': round(time.perf_counter() - started, 3),
                      'notice': 'Đây là dự đoán từ ảnh, chưa xác nhận chẩn đoán. Điểm model không phải xác suất chẩn đoán đúng.'}
            with self.records_lock:
                now = self.clock()
                self.records = OrderedDict((key, value) for key, value in self.records.items() if value[0] > now)
                self.records[record['analysis_id']] = (now + self.ttl, record)
                while len(self.records) > 64:
                    self.records.popitem(last=False)
            return record
        finally:
            self.inference_lock.release()

    def get(self, identifier):
        if not isinstance(identifier, str) or not 16 <= len(identifier) <= 128:
            raise ImageAnalysisError('Mã phân tích ảnh không hợp lệ.')
        with self.records_lock:
            value = self.records.get(identifier)
            if value is None or value[0] <= self.clock():
                self.records.pop(identifier, None)
                raise ImageAnalysisError('Kết quả ảnh đã hết hạn hoặc API vừa khởi động lại. Hãy quét lại ảnh.', 410)
            return value[1]


def image_reference_query(record, question, initial=False):
    """Use an image topic only for a clearly related, otherwise underspecified follow-up."""
    primary = record['primary']
    if initial:
        return CLASSES[primary['class_name']][2] if primary else question
    topics, general, smoke = reference_scope(question)
    _, negative, _ = query_topics(question)
    if topics or general or smoke or negative or not primary or primary['class_name'] == 'bong':
        return question
    text = fold(question)
    related = any(phrase in text for phrase in ('vet nay', 'vet do', 'cho bi thuong', 'vung da nay'))
    short_care_question = re.fullmatch(
        r'(?:(?:toi nen|nen) )?(?:rua|lam sach|sat trung|ve sinh) (?:the nao|nhu the nao|ra sao|bang gi)', text)
    if is_wound_care_question(question) and (related or short_care_question):
        return CLASSES[primary['class_name']][2] + '\n' + question
    return question


def image_reference_queries(record, question, initial=False):
    """User-reported warning signs take priority over a routine predicted wound class."""
    positive, _, _ = query_topics(question)
    related_care = is_wound_care_question(question) and not positive & {
        'thermal_burn', 'chemical_burn', 'electrical_burn', 'bruise'}
    reports = record.get('observations', {})
    priority = [query for key, (_, query) in OBSERVATIONS.items() if reports.get(key)] if initial or related_care else []
    query = image_reference_query(record, question, initial)
    if query and (not initial or not priority):
        priority.append(query)
    return list(dict.fromkeys(priority))


def image_context(record, followup=False):
    """No raw pixels, filename or user-written class label becomes an instruction."""
    primary = record['primary']
    if followup:
        # Metadata only: do not carry the initial "ask questions" instruction
        # into every subsequent user question.
        return json.dumps({'status': record['status'], 'confirmed_diagnosis': False,
                           'prediction': None if primary is None else {
                               'label': primary['label'], 'model_score': primary['confidence']},
                           'user_reported_signs': record.get('observations', {}),
                           'unknown': ['severity', 'cause', 'body_location', 'medical_history']},
                          ensure_ascii=False)
    reported = ', '.join(label for key, (label, _) in OBSERVATIONS.items() if record.get('observations', {}).get(key))
    report_context = 'Người dùng đánh dấu khi gửi ảnh: ' + reported + '. ' if reported else ''
    if primary is None:
        observations = ', '.join(sorted({item['label'] for item in record['detections']})) or 'không có vùng nhận diện rõ'
        return (report_context + 'Ảnh chưa xác định được một loại tổn thương: ' + observations
                + '. Hỏi người dùng mô tả điều đã xảy ra, triệu chứng và gửi ảnh rõ hơn. '
                'Không chọn một class, không kết luận không có vết thương hoặc tình trạng an toàn.')
    label = primary['label']
    details = ('Model ảnh chỉ gợi ý ' + label + '; điểm model '
               + str(round(primary['confidence'] * 100)) + '%, không phải xác suất chẩn đoán đúng. '
               'Chưa biết vị trí cơ thể, mức độ, nguyên nhân, thời điểm hoặc triệu chứng. ')
    if primary['class_name'] == 'bong':
        details += 'Ảnh không phân biệt được bỏng nhiệt, hóa chất hay điện. Hỏi nguyên nhân trước khi đưa hướng dẫn riêng. '
    return report_context + details + 'Nói rõ đây là gợi ý cần đối chiếu và hỏi 1 hoặc 2 chi tiết cần thiết. Không suy ra mức độ nặng nhẹ từ điểm model.'
