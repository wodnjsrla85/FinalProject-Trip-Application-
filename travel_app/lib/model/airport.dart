class Airport {
  final String fNum; // 기종
  final String end; // 도착지
  final String start; // 출발지
  final String company; // 항공사
  final int ePrice; // 이코노미 가격
  final int bPrice; // 비즈니스 가격
  final int fPrice; // 퍼스트 가격
  final int pfPrice; // 프리미엄 이코노미 가격
  final String qTime; // 예상 도착시간
  final String qDate; // 예상 도착 일자
  final String qDuration; // 예상 소요시간 (hh:mm)
  final String date; // 운항일자
  final String time; // 출발시간
  final String name; // 편명
  final String type; // 직항/경유 
  final int tSit; // 총좌석

  Airport({
    required this.fNum,
    required this.end,
    required this.start,
    required this.company,
    required this.ePrice,
    required this.bPrice,
    required this.fPrice,
    required this.pfPrice,
    required this.qTime,
    required this.qDate,
    required this.qDuration,
    required this.date,
    required this.time,
    required this.name,
    required this.type,
    required this.tSit,
  });

  factory Airport.fromMap(Map<String, dynamic> map, String docId) {
    return Airport(
      fNum: map['기종'] ?? "",
      end: map['목적지'] ?? "",
      start: map['출발지'] ?? "",
      company: map['항공사'] ?? "", // ✅ 오타 수정
      ePrice: (map['비수기_이코노미_평균운임'] as num?)?.toInt() ?? 0,
      bPrice: (map['비수기_비즈니스_평균운임'] as num?)?.toInt() ?? 0,
      fPrice: (map['비수기_퍼스트_평균운임'] as num?)?.toInt() ?? 0,
      pfPrice: (map['비수기_프리미엄이코노미_평균운임'] as num?)?.toInt() ?? 0,
      qTime: map['예상 도착시간'] ?? "",
      qDate: map['예상 도착일자'] ?? "",
      qDuration: map['예상 소요(hh:mm)'] ?? "",
      date: map['운항일자'] ?? "",
      time: map['출발시간'] ?? "",
      name: map['운항편명'] ?? "",
      type: map['직항/경유'] ?? "",
      tSit: (map['총좌석'] as num?)?.toInt() ?? 0,
    );
  }
}
