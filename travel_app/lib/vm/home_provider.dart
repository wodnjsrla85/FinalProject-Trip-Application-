import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../model/airport.dart';

/// 선택 값 Provider
final selectedStartProvider = StateProvider<String?>((ref) => null);
final selectedEndProvider = StateProvider<String?>((ref) => null);
final departureDateProvider = StateProvider<String?>((ref) => null);
final returnDateProvider = StateProvider<String?>((ref) => null);
final travelersProvider = StateProvider<int>((ref) => 1);
final searchStateProvider = StateProvider<bool>((ref) => false);

final userInfoProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid) // uid 기준으로 가져옴
      .get();

  if (!doc.exists) return null;
  return doc.data();
});

final flightsProvider = StreamProvider<List<Airport>>((ref) {
  final start = ref.watch(selectedStartProvider);
  final end = ref.watch(selectedEndProvider);

  if (start == null || end == null) {
    return const Stream.empty();
  }

  final startStream = FirebaseFirestore.instance
      .collection("airplane_start")
      .where("출발지", isEqualTo: start)
      .where("목적지", isEqualTo: end)
      .snapshots();

  final endStream = FirebaseFirestore.instance
      .collection("airplane_end")
      .where("출발지", isEqualTo: start)
      .where("목적지", isEqualTo: end)
      .snapshots();

  return Rx.combineLatest2(
    startStream,
    endStream,
    (startSnap, endSnap) {
      final allDocs = [...startSnap.docs, ...endSnap.docs];
      return allDocs.map((doc) => Airport.fromMap(doc.data(), doc.id)).toList();
    },
  );
});



/// 출발지 고유값 Provider
final uniqueStartProvider = StreamProvider<List<String>>((ref) {
  final query = FirebaseFirestore.instance.collection("airplane_start");

  return query.snapshots().map((snapshot) {
    final allStarts = snapshot.docs.map((doc) => doc["출발지"] as String);
    final uniqueStarts = allStarts.toSet().toList(); // 중복 제거
    return uniqueStarts;
  });
});

/// 목적지 고유값 Provider
final uniqueEndProvider = StreamProvider<List<String>>((ref) {
  final query = FirebaseFirestore.instance.collection("airplane_start");

  return query.snapshots().map((snapshot) {
    final allEnds = snapshot.docs.map((doc) => doc["목적지"] as String);
    final uniqueEnds = allEnds.toSet().toList(); // 중복 제거
    return uniqueEnds;
  });
});
