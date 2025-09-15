import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/model/booking.dart';

class BookingProvider {
  final bookingRef = FirebaseFirestore.instance.collection('booking'); // ✅ 변수명 통일

  // db입력
  Future<void> createBooking({
    required String aid,
    required int pricePerSeat,
    required List<String> selectedSeats,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("로그인한 유저가 없습니다.");
    }

    // 총 금액 계산
    final totalPrice = pricePerSeat * selectedSeats.length;

    // Firestore 문서 자동 생성
    final docRef = bookingRef.doc(); // ✅ bookingRef로 수정

    final booking = Booking(
      aid: aid,
      uEmail: user.email ?? "unknown",
      aPrice: totalPrice,
      bDate: DateTime.now().toIso8601String(),
      bSit: selectedSeats,
      bid: docRef.id,
      bState: "결제완료",
    );

    await docRef.set(booking.toMap());
  }
}
