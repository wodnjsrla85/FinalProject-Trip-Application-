import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/model/booking.dart';

class BookingProvider {
  final bookingRef = FirebaseFirestore.instance.collection('booking');
  final packageRef = FirebaseFirestore.instance.collection('package');

  Future<String> createBooking({
  // 항공권 / 패키지 예약
  // 항공권 / 패키지 예약
Future<String> createBooking({
  required String aid,
  required int pricePerSeat,
  required List<String> selectedSeats,
  required List<String> passports,  // ✅ 추가
  required String payment,          // ✅ 추가
  required List<String> passports,
  required String payment,
  String? flightDate,
  required String what,
  int? passengerCount, // 패키지용 인원 수 추가
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("로그인한 유저가 없습니다.");
  }

  final totalPrice = pricePerSeat * selectedSeats.length;
  // 패키지와 항공권에 따라 다른 가격 계산
  final int totalPrice;
  final List<String> seats; // bSit에 들어갈 데이터

  if (what == "패키지") {
    // 패키지: pricePerSeat * passengerCount
    totalPrice = pricePerSeat * (passengerCount ?? 1);
    // 패키지는 인원 수를 문자열로 저장
    seats = [passengerCount.toString()]; // 예: ["3"]
  } else {
    // 항공권: pricePerSeat * selectedSeats.length
    totalPrice = pricePerSeat * selectedSeats.length;
    // 항공권은 실제 좌석 번호들
    seats = selectedSeats; // 예: ["A1", "A2"]
  }

  final docRef = bookingRef.doc();

  final booking = Booking(
    aid: aid,
    uEmail: user.email ?? "unknown",
    aPrice: totalPrice,
    bDate: DateTime.now().toIso8601String(),
    bSit: selectedSeats,
    bDate: DateTime.now().toString().substring(0, 10),
    bSit: seats, // 수정된 부분
    bid: docRef.id,
    bState: "결제완료",
    passports: passports,   // ✅ 저장
    payment: payment,       // ✅ 저장
    what: what,       // ✅ 저장
    passports: passports,
    payment: payment,
    what: what,
  );

  await docRef.set(booking.toMap());
  return docRef.id;
}


  // ✅ 특정 항공편 예약 좌석 불러오기
  // 특정 항공편 예약 좌석 불러오기
  Future<Set<String>> getOccupiedSeats(String aid) async {
    final querySnapshot = await bookingRef
        .where('aid', isEqualTo: aid)
        .where('bState', isEqualTo: '결제완료')
        .get();

    final seats = querySnapshot.docs
        .map((doc) => List<String>.from(doc['bSit'])) // bSit 배열 가져오기
        .expand((s) => s) // flatten
        .map((doc) => List<String>.from(doc['bSit']))
        .expand((s) => s)
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
    final bookings = querySnapshot.docs
        .map((doc) => Booking.fromMap(doc.data(), doc.id))
        .toList();

    // 앱에서 날짜순 정렬
    bookings.sort((a, b) => b.bDate!.compareTo(a.bDate!));
    return bookings;
  }

  // 특정 예약 조회
  Future<Booking?> getBookingById(String bookingId) async {
    final doc = await bookingRef.doc(bookingId).get();
    if (doc.exists && doc.data() != null) {
      return Booking.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // 현재 로그인한 사용자의 패키지 예약만 조회
  Future<List<Booking>> getMyPackageBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인한 유저가 없습니다.");

    final querySnapshot = await bookingRef
        .where('uEmail', isEqualTo: user.email)
        .where('what', isEqualTo: '패키지')
        .get();

    return querySnapshot.docs
        .map((doc) => Booking.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 패키지 예약과 패키지 정보 함께 조회
  Future<List<Map<String, dynamic>>> getMyPackageBookingsWithDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인한 유저가 없습니다.");

    // 1. 패키지 예약들 가져오기
    final bookingSnapshot = await bookingRef
        .where('uEmail', isEqualTo: user.email)
        .where('what', isEqualTo: '패키지')
        .get();

    final bookings = bookingSnapshot.docs
        .map((doc) => Booking.fromMap(doc.data(), doc.id))
        .toList();

    // 2. 각 예약의 패키지 정보 가져오기
    final result = <Map<String, dynamic>>[];

    for (final booking in bookings) {
      Map<String, dynamic>? packageInfo;

      if (booking.aid != null) {
        try {
          final packageDoc = await packageRef.doc(booking.aid).get();
          if (packageDoc.exists) {
            packageInfo = packageDoc.data();
          }
        } catch (e) {
          print('패키지 정보 조회 실패: $e');
        }
      }

      result.add({
        'booking': booking,
        'package': packageInfo,
      });
    }

    return result;
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
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
  }
}

// Provider를 클래스 밖으로 이동
final bookingRepositoryProvider = Provider<BookingProvider>((ref) {
  return BookingProvider();
});