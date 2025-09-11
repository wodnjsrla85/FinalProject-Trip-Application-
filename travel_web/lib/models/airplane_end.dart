class AirplaneEnd {
  final String id;
  final String distanceType;   // 거리구분
  final String aircraft;       // 기종
  final String destination;    // 목적지 (보통 ICN)
  final int offpeakBusiness;   // 비수기_비즈니스_평균운임
  final int offpeakEconomy;    // 비수기_이코노미_평균운임
  final int offpeakFirst;      // 비수기_퍼스트_평균운임
  final int offpeakPremium;    // 비수기_프리미엄이코노미_평균운임
  final String status;         // 상태
  final int peakBusiness;      // 성수기_비즈니스_평균운임
  final int peakEconomy;       // 성수기_이코노미_평균운임
  final int peakFirst;         // 성수기_퍼스트_평균운임
  final int peakPremium;       // 성수기_프리미엄이코노미_평균운임
  final String arrivalTime;    // 예상 도착시간
  final String arrivalDate;    // 예상 도착일자
  final int durationMin;       // 예상 소요 시간
  final String durationHHMM;   // 예상 소요(hh:mm)
  final String flightDate;     // 운항일자
  final String flightNo;       // 운항편명
  final String directType;     // 직항/경유
  final bool isDirect;         // 직항여부
  final int totalSeats;        // 총좌석
  final String departureTime;  // 출발시간
  final String origin;         // 출발지 (ICN으로 들어옴)
  final String terminal;       // 터미널
  final String airline;        // 항공사

  AirplaneEnd({
    required this.id,
    required this.distanceType,
    required this.aircraft,
    required this.destination,
    required this.offpeakBusiness,
    required this.offpeakEconomy,
    required this.offpeakFirst,
    required this.offpeakPremium,
    required this.status,
    required this.peakBusiness,
    required this.peakEconomy,
    required this.peakFirst,
    required this.peakPremium,
    required this.arrivalTime,
    required this.arrivalDate,
    required this.durationMin,
    required this.durationHHMM,
    required this.flightDate,
    required this.flightNo,
    required this.directType,
    required this.isDirect,
    required this.totalSeats,
    required this.departureTime,
    required this.origin,
    required this.terminal,
    required this.airline,
  });

  factory AirplaneEnd.fromJson(String id, Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    return AirplaneEnd(
      id: id,
      distanceType: json['거리구분'] ?? '',
      aircraft: json['기종'] ?? '',
      destination: json['목적지'] ?? '',
      offpeakBusiness: asInt(json['비수기_비즈니스_평균운임']),
      offpeakEconomy: asInt(json['비수기_이코노미_평균운임']),
      offpeakFirst: asInt(json['비수기_퍼스트_평균운임']),
      offpeakPremium: asInt(json['비수기_프리미엄이코노미_평균운임']),
      status: json['상태'] ?? '',
      peakBusiness: asInt(json['성수기_비즈니스_평균운임']),
      peakEconomy: asInt(json['성수기_이코노미_평균운임']),
      peakFirst: asInt(json['성수기_퍼스트_평균운임']),
      peakPremium: asInt(json['성수기_프리미엄이코노미_평균운임']),
      arrivalTime: json['예상 도착시간'] ?? '',
      arrivalDate: json['예상 도착일자'] ?? '',
      durationMin: asInt(json['예상 소요 시간']),
      durationHHMM: json['예상 소요(hh:mm)'] ?? '',
      flightDate: json['운항일자'] ?? '',
      flightNo: json['운항편명'] ?? '',
      directType: json['직항/경유'] ?? '',
      isDirect: asInt(json['직항여부']) == 1,
      totalSeats: asInt(json['총좌석']),
      departureTime: json['출발시간'] ?? '',
      origin: json['출발지'] ?? '',
      terminal: json['터미널'] ?? '',
      airline: json['항공사'] ?? '',
    );
  }
}