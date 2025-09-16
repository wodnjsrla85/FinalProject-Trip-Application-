import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("이용약관"),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''
여행 앱 이용약관

제1조 (목적)
본 약관은 이용자가 본 서비스를 통해 항공권 및 여행 패키지를 예약하고 관련 서비스를 이용함에 있어 필요한 사항을 규정합니다.

제2조 (정의)
- "회원": 본 서비스에 가입하여 항공권·패키지 예약을 이용하는 자
- "예약": 항공권/여행 상품 선택 및 결제 완료 행위

제3조 (약관의 효력 및 변경)
- 본 약관은 앱에 게시함으로써 효력을 가집니다.
- 필요 시 사전 공지 후 변경될 수 있습니다.

제4조 (회원가입)
- 회원은 이메일과 비밀번호로 가입합니다.
- 타인의 정보 도용 시 법적 책임이 발생합니다.

제5조 (서비스의 제공)
- 항공권 예약, 여행 패키지 예약, 예약 확인/취소/환불 서비스

제6조 (결제 및 환불)
- 결제는 신용카드/간편결제 등으로 이루어집니다.
- 환불은 항공사 및 여행사 정책을 따릅니다.

제7조 (이용자의 의무)
- 회원은 법령과 약관을 준수해야 하며, 부정 예약/사기 행위는 금지됩니다.

제8조 (면책조항)
- 천재지변, 항공사/여행사 사정 등 불가항력 사유로 인한 손해는 책임지지 않습니다.

제9조 (관할법원)
- 본 약관에 관한 분쟁은 대한민국 법령 및 회사 소재지 관할 법원에 따릅니다.
          ''',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}
