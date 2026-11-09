# -*- coding: utf-8 -*-
"""CLI script to run offline YOLO wound detection directly from best.pt without an active HTTP server."""
import base64
import json
import math
import os
from pathlib import Path
import secrets
import sys
import time
import warnings

# Thư mục gốc
BACKEND_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BACKEND_DIR.parent
MODEL_PATH = PROJECT_DIR / 'lib' / 'AI_Model' / 'best.pt'

CLASSES = {
    'tray_xuoc': ('Trầy xước', 'abrasion'),
    'vet_cat_rach': ('Vết cắt, rách', 'cut_laceration'),
    'bong': ('Bỏng', 'burn'),
    'bam_tim': ('Bầm', 'bruise'),
}

def run_prediction(image_path_or_base64, contrast=1.0):
    started = time.perf_counter()
    from PIL import Image, ImageEnhance, ImageOps

    # Đọc ảnh
    if os.path.isfile(image_path_or_base64):
        with Image.open(image_path_or_base64) as original:
            image = ImageOps.exif_transpose(original).convert('RGB')
    else:
        # Giả định là base64
        raw = base64.b64decode(image_path_or_base64)
        import io
        with Image.open(io.BytesIO(raw)) as original:
            image = ImageOps.exif_transpose(original).convert('RGB')

    if contrast != 1.0:
        image = ImageEnhance.Contrast(image).enhance(contrast)

    # Nạp YOLO model
    if not MODEL_PATH.is_file():
        return {
            'error': f'Không tìm thấy file model tại: {MODEL_PATH}'
        }

    os.environ.setdefault('YOLO_OFFLINE', 'true')
    os.environ.setdefault('YOLO_AUTOINSTALL', 'false')
    from ultralytics import YOLO

    model = YOLO(str(MODEL_PATH), task='detect')
    result = model.predict(source=image, device='cpu', conf=0.25, imgsz=640, max_det=20, verbose=False, save=False)[0]

    detections = []
    for box in result.boxes:
        cls_id = int(box.cls.item())
        cls_name = model.names[cls_id]
        score = float(box.conf.item())
        coords = box.xyxy[0].tolist()

        if cls_name in CLASSES:
            label, topic = CLASSES[cls_name]
            detections.append({
                'class_id': cls_id,
                'class_name': cls_name,
                'label': label,
                'topic_id': topic,
                'confidence': round(score, 4),
                'box': [max(0, min(float(x), image.width if i % 2 == 0 else image.height)) for i, x in enumerate(coords)]
            })

    detections.sort(key=lambda item: item['confidence'], reverse=True)
    detections = detections[:20]
    strong = [item for item in detections if item['confidence'] >= 0.5]
    distinct = {item['class_name'] for item in strong}
    status = 'detected' if len(distinct) == 1 else ('multiple' if distinct else 'uncertain')
    if not detections:
        status = 'no_detection'
    primary = strong[0] if status == 'detected' else None

    output = {
        'analysis_id': secrets.token_urlsafe(24),
        'status': status,
        'detections': detections,
        'primary': primary,
        'image_width': image.width,
        'image_height': image.height,
        'device': 'cpu',
        'observations': {},
        'analysis_seconds': round(time.perf_counter() - started, 3),
        'notice': 'Đây là dự đoán offline trực tiếp từ mô hình YOLOv8 (best.pt).'
    }
    return output

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'Thiếu tham số đường dẫn ảnh hoặc file base64'}))
        sys.exit(1)

    input_data = sys.argv[1]
    contrast_val = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0

    try:
        # Nếu input_data là tên file chứa base64
        if os.path.isfile(input_data) and input_data.endswith('.b64'):
            with open(input_data, 'r', encoding='utf-8') as f:
                input_data = f.read().strip()

        res = run_prediction(input_data, contrast=contrast_val)
        print(json.dumps(res, ensure_ascii=False))
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)
