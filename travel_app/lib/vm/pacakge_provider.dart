import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/travel_package.dart';

final packageProvider = StreamProvider<List<TravelPackage>>((ref) {
  final collection = FirebaseFirestore.instance
      .collection("package"); // ⚠️ 실제 컬렉션 이름 확인 필요

  return collection.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return TravelPackage.fromMap(doc.data(), doc.id);
    }).toList();
  });
});
