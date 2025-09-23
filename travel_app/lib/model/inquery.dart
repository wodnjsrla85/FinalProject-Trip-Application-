class Inquery {
  final String id;      // Firestore 문서 ID
  final String uEmail;  // 사용자 이메일
  final String aEmail;  // 관리자/상대 이메일
  final String date;    // 문의 작성 날짜
  final String state;   // 상태 (예: 대기중, 처리중, 완료)
  final String content; // 문의 내용
  final String title;   // 문의 제목
  final String to;   // 문의 제목

  Inquery({
    required this.id,
    required this.uEmail,
    required this.aEmail,
    required this.date,
    required this.state,
    required this.content,
    required this.title,
    required this.to,
  });

  /// Firestore → Inquery 객체 변환
  factory Inquery.fromMap(Map<String, dynamic> map, String docId) {
    return Inquery(
      id: docId,
      uEmail: map['uEmail'] ?? "",
      aEmail: map['aEmail'] ?? "",
      date: map['date'] ?? "",
      state: map['state'] ?? "",
      content: map['content'] ?? "",
      title: map['title'] ?? "",
      to: map['to'] ?? "",
    );
  }

  /// Inquery 객체 → Firestore 저장용 Map
  Map<String, dynamic> toMap() {
    return {
      "uEmail": uEmail,
      "aEmail": aEmail,
      "date": date,
      "state": state,
      "content": content,
      "title": title,
      "to" : to,
    };
  }
}
