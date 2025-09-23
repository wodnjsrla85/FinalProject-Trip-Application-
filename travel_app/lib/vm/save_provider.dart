import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/model/save.dart';

class SaveProvider {

final packageSavedProvider =StateProvider.family<bool, String>((ref, packageId) => false);
  final saveRef = FirebaseFirestore.instance.collection("save");

  String? get currentEmail => FirebaseAuth.instance.currentUser?.email;

  /// 특정 패키지가 저장돼 있는지 확인
  Future<bool> isPackageSaved(String packageId) async {
    final email = currentEmail;
    if (email == null) return false;

    final doc = await saveRef.doc(email).get();
    if (!doc.exists) return false;

    final save = Save.fromMap(doc.data()!, doc.id);
    return save.packages.contains(packageId);
  }

  /// 저장 토글
  Future<void> togglePackage(String packageId) async {
    final email = currentEmail;
    if (email == null) throw Exception("로그인한 유저가 없습니다.");

    final docRef = saveRef.doc(email);
    final doc = await docRef.get();

    if (doc.exists) {
      final save = Save.fromMap(doc.data()!, doc.id);
      final updated = List<String>.from(save.packages);

      if (updated.contains(packageId)) {
        updated.remove(packageId); // 제거
      } else {
        updated.add(packageId); // 추가
      }

      await docRef.update({"packages": updated});
    } else {
      await docRef.set(Save(id: email, flights: [], packages: [packageId]).toMap());
    }
  }

  Future<bool> isFlightSaved(String flightId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인 필요");

    final docRef = FirebaseFirestore.instance.collection("save").doc(user.email);
    final doc = await docRef.get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final List flights = data["flights"] ?? [];
    return flights.contains(flightId);
  }

  Future<void> toggleFlight(String flightId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인 필요");

    final docRef = FirebaseFirestore.instance.collection("save").doc(user.email);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data()!;
      final List flights = List<String>.from(data["flights"] ?? []);

      if (flights.contains(flightId)) {
        // 이미 있으면 삭제
        await docRef.update({
          "flights": FieldValue.arrayRemove([flightId])
        });
      } else {
        // 없으면 추가
        await docRef.update({
          "flights": FieldValue.arrayUnion([flightId])
        });
      }
    } else {
      // 문서가 없으면 새로 생성
      await docRef.set({
        "flights": [flightId],
        "packages": [],
      });
    }
  }
}

