from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import cv2
import pytesseract
import numpy as np
import stripe

# ========================
# FastAPI 앱 초기화
# ========================
app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 개발 단계는 *, 배포 시 특정 도메인으로 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# YOLO MRZ Detection 모델 로드
yolo_model = YOLO("Python/fastAPI/passport_mrz_model4/weights/best.pt")

# Stripe API Key 설정
stripe.api_key = "sk_test_51SAMUwDU3DihCdHE5YZSH9ccfNCWa6dX9IQnqyvCc8ok4joKld4RJBRTIP7HqHdgPcBP8QqtdbjvbMFjqiwsVAE300e8bdNZii"


def preprocess_for_ocr(img):
    if img is None or img.size == 0:
        raise ValueError("OCR 전처리 단계에서 이미지가 비어있음")
    gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    _, thresh = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return thresh


@app.post("/extract-passport-info/")
async def extract_passport_info(image: UploadFile = File(...)):
    try:
        # 1. 이미지 바이트 읽기
        image_bytes = await image.read()
        np_arr = np.frombuffer(image_bytes, np.uint8)

        # 2. OpenCV 이미지 디코딩
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        if img is None:
            return JSONResponse({"error": "이미지를 디코딩할 수 없습니다."}, status_code=400)
        print("원본 이미지 shape:", img.shape)

        # 3. RGB 변환
        rgb_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        # 4. YOLO MRZ 탐지
        results = yolo_model.predict(rgb_img)[0]
        boxes = results.boxes
        if boxes is None or len(boxes) == 0:
            return JSONResponse({"error": "MRZ 영역이 감지되지 않았습니다."}, status_code=400)

        # 5. 신뢰도 가장 높은 박스 선택
        confs = boxes.conf.cpu().numpy()
        best_idx = confs.argmax()
        x_center, y_center, bw, bh = boxes.xywh[best_idx].cpu().numpy()

        x1 = max(0, int(x_center - bw / 2))
        y1 = max(0, int(y_center - bh / 2))
        x2 = min(rgb_img.shape[1], int(x_center + bw / 2))
        y2 = min(rgb_img.shape[0], int(y_center + bh / 2))

        if x2 <= x1 or y2 <= y1:
            return JSONResponse({"error": "잘못된 crop 좌표"}, status_code=400)

        mrz_crop = rgb_img[y1:y2, x1:x2]
        if mrz_crop.size == 0:
            return JSONResponse({"error": "MRZ crop이 비어 있음"}, status_code=400)

        print("MRZ crop shape:", mrz_crop.shape)

        # 6. 두 번째 라인 OCR
        h_crop = mrz_crop.shape[0]
        line2_img = mrz_crop[h_crop // 2:, :]
        config = '--psm 7 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789<'
        line2 = pytesseract.image_to_string(preprocess_for_ocr(line2_img), config=config).strip().replace(" ", "")
        print("MRZ Line2 OCR:", line2)

        if len(line2) < 13:
            return JSONResponse({"error": "OCR 결과가 너무 짧음", "raw_ocr": line2}, status_code=422)

        passport_number = line2[0:9]
        nationality = line2[10:13]

        return {
            "passport_number": passport_number,
            "nationality": nationality,
            "raw_ocr_line2": line2
        }

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


# ========================
# Stripe 결제 API
# ========================
@app.post("/create-payment-intent/")
async def create_payment_intent(data: dict):
    try:
        amount = data.get("amount", 1000)
        currency = data.get("currency", "usd")

        intent = stripe.PaymentIntent.create(
            amount=amount,
            currency=currency,
            automatic_payment_methods={"enabled": True},
        )

        return {"clientSecret": intent.client_secret}

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
