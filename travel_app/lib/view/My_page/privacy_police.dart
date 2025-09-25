import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        "title": "1. 수집하는 개인정보 항목",
        "icon": Icons.person_outline,
        "content": "- 회원가입 시: 이메일, 비밀번호, 이름, 휴대전화번호\n"
            "- 예약 시: 여권번호, 생년월일, 탑승자 정보, 결제 정보\n"
            "- 자동 수집: 접속 IP, 기기정보, 이용기록",
      },
      {
        "title": "2. 개인정보의 이용 목적",
        "icon": Icons.task_alt,
        "content": "- 항공권 및 여행 패키지 예약/결제 처리\n"
            "- 예약 확인 및 고객 상담 서비스\n"
            "- 맞춤형 여행 상품 추천(동의 시)\n"
            "- 법적 의무 준수",
      },
      {
        "title": "3. 개인정보 보유 및 이용 기간",
        "icon": Icons.access_time,
        "content": "- 회원 탈퇴 시 지체 없이 파기\n"
            "- 단, 전자상거래 기록: 5년\n"
            "- 소비자 불만/분쟁 처리: 3년",
      },
      {
        "title": "4. 개인정보 제3자 제공",
        "icon": Icons.share_outlined,
        "content": "- 항공사/여행사: 예약 및 발권\n"
            "- 결제 대행사: 결제 승인 및 환불",
      },
      {
        "title": "5. 개인정보 보호 조치",
        "icon": Icons.lock_outline,
        "content": "- 암호화 저장\n"
            "- 접근권한 최소화\n"
            "- 정기적 보안 점검",
      },
      {
        "title": "6. 이용자의 권리",
        "icon": Icons.verified_user_outlined,
        "content": "- 본인 정보 열람·정정·삭제\n"
            "- 마케팅 수신 거부 가능",
      },
      {
        "title": "7. 개인정보 보호 책임자",
        "icon": Icons.support_agent,
        "content": "- 이름: [담당자명]\n"
            "- 이메일: [이메일]\n"
            "- 전화번호: [전화번호]",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "개인정보 처리방침",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "여행 앱 개인정보 처리방침",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "본 앱(이하 '서비스')은 이용자의 개인정보를 중요시하며 "
            "「개인정보 보호법」 등 관련 법령을 준수합니다.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...sections.map((section) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(section["icon"] as IconData,
                            color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            section["title"] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      section["content"] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "최종 수정일: 2025-09-24",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
