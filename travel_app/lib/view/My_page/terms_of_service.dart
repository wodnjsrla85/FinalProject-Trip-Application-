import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        "title": "제1조 (목적)",
        "icon": Icons.flag_outlined,
        "content":
            "본 약관은 이용자가 본 서비스를 통해 항공권 및 여행 패키지를 예약하고 관련 서비스를 이용함에 있어 필요한 사항을 규정합니다.",
      },
      {
        "title": "제2조 (정의)",
        "icon": Icons.info_outline,
        "content":
            "- \"회원\": 본 서비스에 가입하여 항공권·패키지 예약을 이용하는 자\n"
            "- \"예약\": 항공권/여행 상품 선택 및 결제 완료 행위",
      },
      {
        "title": "제3조 (약관의 효력 및 변경)",
        "icon": Icons.gavel_outlined,
        "content":
            "- 본 약관은 앱에 게시함으로써 효력을 가집니다.\n"
            "- 필요 시 사전 공지 후 변경될 수 있습니다.",
      },
      {
        "title": "제4조 (회원가입)",
        "icon": Icons.person_add_alt_1,
        "content":
            "- 회원은 이메일과 비밀번호로 가입합니다.\n"
            "- 타인의 정보 도용 시 법적 책임이 발생합니다.",
      },
      {
        "title": "제5조 (서비스의 제공)",
        "icon": Icons.flight_takeoff,
        "content":
            "- 항공권 예약, 여행 패키지 예약\n"
            "- 예약 확인 / 취소 / 환불 서비스",
      },
      {
        "title": "제6조 (결제 및 환불)",
        "icon": Icons.payment,
        "content":
            "- 결제는 신용카드/간편결제 등으로 이루어집니다.\n"
            "- 환불은 항공사 및 여행사 정책을 따릅니다.",
      },
      {
        "title": "제7조 (이용자의 의무)",
        "icon": Icons.rule,
        "content":
            "- 회원은 법령과 약관을 준수해야 합니다.\n"
            "- 부정 예약 및 사기 행위는 금지됩니다.",
      },
      {
        "title": "제8조 (면책조항)",
        "icon": Icons.warning_amber_rounded,
        "content":
            "- 천재지변, 항공사/여행사 사정 등 불가항력 사유로 인한 손해는 책임지지 않습니다.",
      },
      {
        "title": "제9조 (관할법원)",
        "icon": Icons.account_balance,
        "content":
            "- 본 약관에 관한 분쟁은 대한민국 법령 및 회사 소재지 관할 법원에 따릅니다.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "이용약관",
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
            "여행 앱 이용약관",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "본 약관은 본 서비스를 이용하는 모든 회원에게 적용되며, "
            "항공권 및 여행 패키지 예약과 관련된 권리와 의무를 규정합니다.",
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
              "시행일자: 2025-09-24",
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
