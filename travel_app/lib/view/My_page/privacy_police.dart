import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("개인정보 처리방침"),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''
여행 앱 개인정보 처리방침

본 앱(이하 "서비스")은 이용자의 개인정보를 중요시하며 「개인정보 보호법」 등 관련 법령을 준수합니다.

1. 수집하는 개인정보 항목
- 회원가입 시: 이메일, 비밀번호, 이름, 휴대전화번호
- 예약 시: 여권번호, 생년월일, 탑승자 정보, 결제 정보
- 자동 수집: 접속 IP, 기기정보, 이용기록

2. 개인정보의 이용 목적
- 항공권 및 여행 패키지 예약/결제 처리
- 예약 확인 및 고객 상담 서비스
- 맞춤형 여행 상품 추천(동의 시)
- 법적 의무 준수

3. 개인정보 보유 및 이용 기간
- 회원 탈퇴 시 지체 없이 파기
- 단, 전자상거래 기록: 5년, 소비자 불만/분쟁 처리: 3년

4. 개인정보 제3자 제공
- 항공사/여행사: 예약 및 발권
- 결제 대행사: 결제 승인 및 환불

5. 개인정보 보호 조치
- 암호화 저장, 접근권한 최소화, 정기적 보안 점검

6. 이용자의 권리
- 본인 정보 열람·정정·삭제, 마케팅 수신 거부 가능

7. 개인정보 보호 책임자
- 이름: [담당자명]
- 이메일: [이메일]
- 전화번호: [전화번호]
          ''',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}
