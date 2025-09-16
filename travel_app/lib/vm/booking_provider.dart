import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/model/booking.dart';

class BookingProvider {
  final bookingRef = FirebaseFirestore.instance.collection('booking');

  Future<String> createBooking({
  required String aid,
  required int pricePerSeat,
  required List<String> selectedSeats,
  required List<String> passports,  // ✅ 추가
  required String payment,          // ✅ 추가
  String? flightDate,
  required String what,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("로그인한 유저가 없습니다.");
  }

  final totalPrice = pricePerSeat * selectedSeats.length;
  final docRef = bookingRef.doc();

  final booking = Booking(
    aid: aid,
    uEmail: user.email ?? "unknown",
    aPrice: totalPrice,
    bDate: flightDate ?? DateTime.now().toIso8601String(),
    bSit: selectedSeats,
    bid: docRef.id,
    bState: "결제완료",
    passports: passports,   // ✅ 저장
    payment: payment,       // ✅ 저장
    what: what,       // ✅ 저장
  );

  await docRef.set(booking.toMap());
  return docRef.id;
}


  // ✅ 특정 항공편 예약 좌석 불러오기
  Future<Set<String>> getOccupiedSeats(String aid) async {
    final querySnapshot = await bookingRef
        .where('aid', isEqualTo: aid)
        .where('bState', isEqualTo: '결제완료')
        .get();

    final seats = querySnapshot.docs
        .map((doc) => List<String>.from(doc['bSit'])) // bSit 배열 가져오기
        .expand((s) => s) // flatten
        .toSet();

    return seats;
  }

  // 사용자의 예약 목록 조회
  Future<List<Booking>> getUserBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("로그인한 유저가 없습니다.");
    }

    final querySnapshot = await bookingRef
        .where('uEmail', isEqualTo: user.email)
        .orderBy('bDate', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Booking.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 특정 예약 조회
  Future<Booking?> getBookingById(String bookingId) async {
    final doc = await bookingRef.doc(bookingId).get();
    if (doc.exists && doc.data() != null) {
      return Booking.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // 예약 상태 업데이트
  Future<void> updateBookingState(String bookingId, String newState) async {
    await bookingRef.doc(bookingId).update({'bState': newState});
  }

  // 예약 취소
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingState(bookingId, "취소됨");
  }

  // 예약 삭제
  Future<void> deleteBooking(String bookingId) async {
    await bookingRef.doc(bookingId).delete();
  }

  // 실시간 예약 상태 스트림
  Stream<List<Booking>> getUserBookingsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return bookingRef
        .where('uEmail', isEqualTo: user.email)
        .orderBy('bDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList());
  }
}
