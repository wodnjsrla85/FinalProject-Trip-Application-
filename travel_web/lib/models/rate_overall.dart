class RateRowOverall {
  final String flightId;
  final String collection; // 'airplane_start' or 'airplane_end'
  final String flightNo;
  final String origin;
  final String dest;
  final String date;     // 운항일자
  final int capacity;    // 전체 좌석(= 문서의 총좌석, 또는 등급합)
  final int booked;      // 전체 예약 좌석(모든 등급 합산)
  final double rate;     // booked / capacity (0~1)

  RateRowOverall({
    required this.flightId,
    required this.collection,
    required this.flightNo,
    required this.origin,
    required this.dest,
    required this.date,
    required this.capacity,
    required this.booked,
    required this.rate,
  });
}