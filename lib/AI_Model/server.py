# -*- coding: utf-8 -*-
import io
import os
import sys
import traceback
from typing import Dict, Any, List

# Thêm thư mục hiện tại vào sys.path
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
if CURRENT_DIR not in sys.path:
    sys.path.insert(0, CURRENT_DIR)

LOG_FILE = os.path.join(CURRENT_DIR, "server.log")
log_f = open(LOG_FILE, "a", encoding="utf-8")
sys.stdout = log_f
sys.stderr = log_f

from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from PIL import Image, ImageEnhance

try:
    from ultralytics import YOLO
except ImportError:
    print("==================================================================")
    print(" LỖI: Chưa cài đặt thư viện 'ultralytics'. Vui lòng chạy lệnh sau:")
    print(" pip install ultralytics fastapi uvicorn python-multipart pillow")
    print("==================================================================")
    sys.exit(1)

# Khởi tạo FastAPI App
app = FastAPI(
    title="Wound Detection AI Server (YOLOv8)",
    description="API nhận diện tổn thương da sử dụng mô hình YOLOv8 train sẵn",
    version="1.0.0",
)

# Cho phép CORS để Flutter Web & Desktop gọi được không bị chặn
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Đường dẫn model best.pt (nằm cùng thư mục với server.py)
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(CURRENT_DIR, "best.pt")

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Không tìm thấy file model tại: {MODEL_PATH}")

print(f"[*] Đang tải mô hình YOLO từ: {MODEL_PATH} ...")
model = YOLO(MODEL_PATH)
print("[+] Tải mô hình YOLO thành công! Danh sách nhãn:", model.names)

# Bảng ánh xạ nhãn model -> Tiếng Việt & Topic hướng dẫn sơ cứu
CLASS_MAPPING = {
    "tray_xuoc": {
        "vn_label": "Trầy xước",
        "topic_id": "abrasion",
        "severity": "Nhẹ",
        "guide": "Cách xử lý và sát trùng vết trầy xước ngoài da",
    },
    "vet_cat_rach": {
        "vn_label": "Vết cắt / Vết rách",
        "topic_id": "cut_laceration",
        "severity": "Cần chú ý",
        "guide": "Cách cầm máu, sát khuẩn và băng bó vết cắt",
    },
    "bong": {
        "vn_label": "Bỏng",
        "topic_id": "burn",
        "severity": "Quan trọng",
        "guide": "Làm mát vùng bỏng và xử lý vết thương nhiệt đúng cách",
    },
    "bam_tim": {
        "vn_label": "Bầm tím",
        "topic_id": "bruise",
        "severity": "Nhẹ",
        "guide": "Chườm lạnh giảm sưng đau tổn thương phần mềm",
    },
}


@app.get("/")
def health_check():
    """Kiểm tra server có đang hoạt động hay không."""
    return {
        "status": "online",
        "message": "AI Wound Detection Server đang sẵn sàng!",
        "model": "YOLOv8 best.pt",
        "supported_classes": list(CLASS_MAPPING.keys()),
    }


@app.post("/predict")
async def predict_wound(
    file: UploadFile = File(...),
    contrast: float = Form(1.0),
):
    """
    Nhận file ảnh từ Flutter, hỗ trợ điều chỉnh contrast (độ tương phản),
    chạy mô hình YOLO nhận diện vết thương và trả về kết quả.
    """
    try:
        contents = await file.read()
        if not contents or len(contents) == 0:
            raise HTTPException(
                status_code=400,
                detail="Tập tin tải lên bị rỗng (0 bytes). Vui lòng chọn lại ảnh."
            )

        image = None
        # 1. Thử giải mã bằng thư viện Pillow
        try:
            image = Image.open(io.BytesIO(contents)).convert("RGB")
        except Exception:
            pass

        # 2. Dự phòng giải mã bằng OpenCV nếu Pillow không đọc được (ví dụ BMP, định dạng đặc thù)
        if image is None:
            try:
                import numpy as np
                import cv2
                np_buf = np.frombuffer(contents, dtype=np.uint8)
                cv_img = cv2.imdecode(np_buf, cv2.IMREAD_COLOR)
                if cv_img is not None:
                    rgb_img = cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB)
                    image = Image.fromarray(rgb_img)
            except Exception:
                pass

        # 3. Nếu cả hai cách đều không mở được ảnh
        if image is None:
            raise HTTPException(
                status_code=400,
                detail="Tập tin tải lên không phải là ảnh hợp lệ hoặc định dạng không được hỗ trợ (chỉ hỗ trợ JPG, PNG, WEBP, BMP)."
            )

        # Nếu người dùng chọn quét lại với tăng/giảm tương phản
        if contrast != 1.0:
            enhancer = ImageEnhance.Contrast(image)
            image = enhancer.enhance(contrast)

        img_width, img_height = image.size

        # Chạy dự đoán với ngưỡng tin cậy conf=0.15
        results = model.predict(source=image, conf=0.15, verbose=False)

        best_detection = None
        max_conf = -1.0
        all_detections: List[Dict[str, Any]] = []

        for r in results:
            boxes = r.boxes
            if boxes is None or len(boxes) == 0:
                continue

            for box in boxes:
                cls_id = int(box.cls[0].item())
                conf = float(box.conf[0].item())
                xyxy = [float(coord) for coord in box.xyxy[0].tolist()]

                class_name_raw = model.names.get(cls_id, str(cls_id))
                mapped = CLASS_MAPPING.get(
                    class_name_raw,
                    {
                        "vn_label": class_name_raw,
                        "topic_id": "abrasion",
                        "severity": "Không xác định",
                        "guide": "Hướng dẫn sơ cứu tổng quát",
                    },
                )

                detection_info = {
                    "class_name_raw": class_name_raw,
                    "vn_label": mapped["vn_label"],
                    "topic_id": mapped["topic_id"],
                    "severity": mapped["severity"],
                    "guide": mapped["guide"],
                    "confidence_percent": round(conf * 100, 1),
                    "box": xyxy,  # [xmin, ymin, xmax, ymax]
                }
                all_detections.append(detection_info)

                if conf > max_conf:
                    max_conf = conf
                    best_detection = detection_info

        # Nếu phát hiện được ít nhất 1 tổn thương
        if best_detection is not None:
            return {
                "success": True,
                "detected": True,
                "injury_type": best_detection["vn_label"],
                "confidence_percent": int(best_detection["confidence_percent"]),
                "confidence_float": best_detection["confidence_percent"],
                "class_id": best_detection["class_name_raw"],
                "topic_id": best_detection["topic_id"],
                "severity": best_detection["severity"],
                "box": best_detection["box"],
                "image_width": img_width,
                "image_height": img_height,
                "contrast_applied": contrast,
                "all_detections": all_detections,
                "message": f"Phát hiện vết thương: {best_detection['vn_label']} ({best_detection['confidence_percent']}%)",
            }
        else:
            return {
                "success": True,
                "detected": False,
                "injury_type": "Không phát hiện tổn thương rõ ràng",
                "confidence_percent": 0,
                "confidence_float": 0.0,
                "class_id": "none",
                "topic_id": "abrasion",
                "severity": "Bình thường",
                "box": None,
                "image_width": img_width,
                "image_height": img_height,
                "contrast_applied": contrast,
                "all_detections": [],
                "message": "Không phát hiện vết thương ngoài da rõ ràng trên bức ảnh này.",
            }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi phân tích hình ảnh: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, log_level="warning")
