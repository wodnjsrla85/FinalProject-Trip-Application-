import 'package:flutter/foundation.dart';

class Booking {
  final String aid;
  final String uEmail;
  final int aPrice;
  final String bDate;
  final List<String> bSit;
  final String bid;      // Firestore 문서 ID (docId와 동일)
  final String bState;

  Booking({
    required this.aid,
    required this.uEmail,
    required this.aPrice,
    required this.bDate,
    required this.bSit,
    required this.bid,
    required this.bState,
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
    };
  }
}
