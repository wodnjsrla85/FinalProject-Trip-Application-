import 'package:cloud_firestore/cloud_firestore.dart';

// 문의 정보를 담는 클래스
class InquiryModel {
  String id;           // 문의 번호
  String title;        // 제목  
  String content;      // 내용
  String uEmail;       // 문의한 사람 이메일
  String date;         // 언제 문의했는지
  String state;        // 상태 (대기중 or 답변완료)
  String to;           // 문의 대상 (항공사, 호텔 등) - 추가된 필드!
  String? reply;       // 답변 (없을 수도 있음)

  // 생성자 - 데이터를 받아서 객체 만들기
  InquiryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.uEmail,
    required this.date,
    required this.state,
    required this.to,    // 필수 필드로 추가!
    this.reply,
  });

  // Firebase 데이터를 우리가 쓸 수 있는 형태로 바꾸기
  static InquiryModel fromFirebase(DocumentSnapshot doc) {
    // Firebase 문서에서 데이터 꺼내기
    var data = doc.data() as Map<String, dynamic>;
    
    // 새로운 InquiryModel 객체 만들어서 반환
    return InquiryModel(
      id: doc.id,
      title: data['title'] ?? '제목 없음',
      content: data['content'] ?? '내용 없음', 
      uEmail: data['uEmail'] ?? '이메일 없음',
      date: data['date'] ?? '날짜 없음',
      state: data['state'] ?? '대기중',
      to: data['to'] ?? '문의대상',        // to 필드 추가!
      reply: data['reply'], // 답변은 없을 수도 있으니까 그냥 두기
    );
  }

  // 답변이 완료되었는지 확인
  bool isAnswered() {
    return state == '답변완료';
  }
  
  // 날짜를 간단하게 보여주기 (2025-09-17 형태)
  String getShortDate() {
    if (date.length >= 10) {
      return date.substring(0, 10); // 앞의 10글자만 자르기
    }
    return date;
  }
  
  // 내용이 길면 줄여서 보여주기
  String getShortContent() {
    if (content.length > 50) {
      return content.substring(0, 50) + '...'; // 50글자 + ...
    }
    return content;
  }
}
