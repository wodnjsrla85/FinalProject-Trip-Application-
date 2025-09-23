class RateRow {
  final String flightId;
  final String flightNo;
  final String origin;
  final String dest;
  final String date;
  final String seatClass;
  final int capacity;
  final int booked;
  final double rate;
  RateRow({
    required this.flightId,
    required this.flightNo,
    required this.origin,
    required this.dest,
    required this.date,
    required this.seatClass,
    required this.capacity,
    required this.booked,
    required this.rate,
  });
}