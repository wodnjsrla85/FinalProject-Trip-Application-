from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from ultralytics import YOLO
import cv2
import pytesseract
import numpy as np
import os

app = FastAPI()
yolo_model = YOLO("/Users/jeongseoyun/Desktop/FinalProject-Trip-Application-/Python/fastAPI/passport_mrz_model4/weights/best.pt")

def preprocess_for_ocr(img):
    gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    _, thresh = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return thresh

@app.post("/extract-passport-info/")
async def extract_passport_info(image: UploadFile = File(...)):
    try:
        image_bytes = await image.read()
        np_arr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        rgb_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        results = yolo_model.predict(rgb_img)[0]
        boxes = results.boxes
        if boxes is None or len(boxes) == 0:
            return JSONResponse({"error": "MRZ 영역이 감지되지 않았습니다."}, status_code=400)

        # 신뢰도 가장 높은 bbox 선택
        confs = boxes.conf.cpu().numpy()
        best_idx = confs.argmax()
        x_center, y_center, bw, bh = boxes.xywh[best_idx].cpu().numpy()
        x1 = int(x_center - bw / 2)
        y1 = int(y_center - bh / 2)
        x2 = int(x_center + bw / 2)
        y2 = int(y_center + bh / 2)

        mrz_crop = rgb_img[y1:y2, x1:x2]
        h_crop = mrz_crop.shape[0]
        line2_img = mrz_crop[h_crop // 2:, :]

        config = '--psm 7 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789<'
        line2 = pytesseract.image_to_string(preprocess_for_ocr(line2_img), config=config).strip().replace(" ", "")
        print("🔍 MRZ Line2:", line2)

        if len(line2) < 13:
            return JSONResponse({"error": "OCR 결과가 너무 짧습니다.", "raw_ocr": line2}, status_code=422)

        passport_number = line2[0:9]
        nationality = line2[10:13]

        return {
            "passport_number": passport_number,
            "nationality": nationality,
            "raw_ocr_line2": line2
        }

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000, log_level="info")