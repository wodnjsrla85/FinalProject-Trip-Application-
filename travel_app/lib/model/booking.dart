import 'package:flutter/foundation.dart';

class Booking {
  final String aid;              // 항공편 ID
  final String uEmail;           // 예약자 이메일
  final int aPrice;              // 총 가격
  final String bDate;            // 예약 날짜
  final List<String> bSit;       // 좌석 목록
  final String bid;              // Firestore 문서 ID
  final String bState;           // 예약 상태
  final List<String> passports;  // 여권 번호 리스트
  final String payment;          // 결제 방식
  final String what;          // 결제 방식

  Booking({
    required this.aid,
    required this.uEmail,
    required this.aPrice,
    required this.bDate,
    required this.bSit,
    required this.bid,
    required this.bState,
    required this.passports,
    required this.payment,
    required this.what,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String docId) {
    return Booking(
      aid: map['aid'] ?? "",
      uEmail: map['uEmail'] ?? "",
      aPrice: (map['aPrice'] ?? 0) as int,
      bDate: map['bDate'] ?? "",
      bSit: List<String>.from(map['bSit'] ?? []),
      bid: docId,
      bState: map['bState'] ?? "",
      passports: List<String>.from(map['passports'] ?? []),
      payment: map['payment'] ?? "",
      what: map['what'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aid': aid,
      'uEmail': uEmail,
      'aPrice': aPrice,
      'bDate': bDate,
      'bSit': bSit,
      'bid': bid,
      'bState': bState,
      'passports': passports,
      'payment': payment,
      'what': what,
    };
  }
}
