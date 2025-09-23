import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/model/inquery.dart';

// 제목 상태
final inqueryTitleProvider = StateProvider<String>((ref) => "");

// 내용 상태
final inqueryContentProvider = StateProvider<String>((ref) => "");

// 로딩 상태
final inqueryLoadingProvider = StateProvider<bool>((ref) => false);

// to 상태 (어플, 항공사, 여행사)
final inqueryToProvider = StateProvider<String>((ref) => "어플");

// 패키지 선택 Provider
final selectedPackageProvider = StateProvider<String?>((ref) => null);

// 선택된 항공편/패키지 refId 저장
final inqueryRefIdProvider = StateProvider<String>((ref) => "");

final inqueryProvider = StreamProvider<List<Inquery>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // 로그인 안 되어있으면 빈 리스트 반환
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection("inquery")
      .where("uEmail", isEqualTo: user.email) // ✅ 조건 추가
      // .orderBy("date", descending: true) // ✅ 최신순 정렬
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Inquery.fromMap(doc.data(), doc.id)).toList());
});

enum InqueryFilter { all, unanswered, answered }

final inqueryFilterProvider = StateProvider<InqueryFilter>((ref) => InqueryFilter.all);



final incompleteInqueryCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection("inquery")
      .where("uEmail", isEqualTo: user.email) // 현재 로그인 유저 문의만
      .snapshots()
      .map((snapshot) {
        int count = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final reply = data["reply"];
          if (reply == null || (reply is String && reply.trim().isEmpty)) {
            count++;
          }
        }
        return count;
      });
});

final pendingReplyCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection("inquery")
      .where("uEmail", isEqualTo: user.email) // 현재 사용자 문의만
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Inquery.fromMap(doc.data(), doc.id))
            .toList();

        // ✅ reply가 있고 비어있지 않으면 "답변 완료"로 카운트
        return list.where((inq) => inq.reply != null && inq.reply!.isNotEmpty).length;
      });
});
