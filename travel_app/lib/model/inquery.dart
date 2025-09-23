class Inquery {
  final String id;
  final String uEmail;
  final String aEmail;
  final String date;
  final String state;
  final String content;
  final String title;
  final String to;
  final String? reply; // ✅ 관리자 답변

  Inquery({
    required this.id,
    required this.uEmail,
    required this.aEmail,
    required this.date,
    required this.state,
    required this.content,
    required this.title,
    required this.to,
    this.reply,
  });

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
      reply: map['reply'], // ✅ 답변 불러오기
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uEmail": uEmail,
      "aEmail": aEmail,
      "date": date,
      "state": state,
      "content": content,
      "title": title,
      "to": to,
      if (reply != null) "reply": reply,
    };
  }
}
