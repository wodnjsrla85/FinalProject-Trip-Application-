# ✈️ AirTravel — AI 기반 항공 예약 & 여권 MRZ 인식 앱
> Flutter · Firebase · Python FastAPI · YOLOv8 · LLaMA 기반 항공 올인원 앱

---

## 📌 프로젝트 소개
**AirTravel**은 항공권 조회/예약, 좌석 선택, 여권 MRZ 자동 인식, AI 기반 항공 챗봇까지 제공하는 **올인원 항공 앱**입니다.  
Flutter 기반으로 개발되었으며, Firebase & Python 백엔드, YOLOv8 MRZ 인식 모델, LLaMA 기반 항공 챗봇까지 포함된 **풀스택 모바일 프로젝트**입니다.

---

## 🚀 주요 기능 (Features)

### 🔹 1. 여권 MRZ 자동 인식 (Passport OCR)
- YOLOv8 기반 MRZ Object Detection  
- OCR(한국/미국/국제 표준) 적용  
- 여권번호, 만료일, 생년월일 자동 추출  
- Perspective Warp · 조명/노이즈 보정  

### 🔹 2. 항공권 조회 & 예약
- 출발/도착 공항 선택  
- 날짜·인원 선택  
- 실시간 항공편 리스트  
- 예약 정보 Firestore 저장  

### 🔹 3. 좌석 선택 (Seat Selection)
- 항공기 좌석 UI 구현  
- 예약된 좌석 표시  
- 좌석 선택 → 예약 흐름 연결  

### 🔹 4. AI 항공 챗봇
- LLaMA3 기반 LoRA 파인튜닝  
- ATIS Dataset + 한국어 QA 데이터  
- 항공권, 수하물 규정, 공항 정보 등 Q&A  

### 🔹 5. 마이페이지 & 대시보드
- 예약 내역 조회  
- 이용 통계 제공  
- 직관적인 네이비/화이트 UI  

### 🔹 6. Firebase 백엔드
- Firebase Auth  
- Firestore  
- Firebase Storage  
- Firebase Hosting (Web)  

---

## 📱 앱 화면 (Screenshots)
> (이미지는 추후 추가 예정)

---

## 🛠️ 기술 스택 (Tech Stack)

### **Frontend**
- Flutter (Dart)
- Riverpod / GetX
- Custom Seat Map UI

### **Backend**
- Firebase (Auth/Firestore/Storage)
- Python FastAPI 서버
- YOLOv8 + PaddleOCR

### **AI**
- LLaMA3.1 8B Instruct  
- LoRA Fine-tuning  
- JSONL 기반 항공 QA 데이터 구축  

---

## 📂 프로젝트 구조 (Structure)

