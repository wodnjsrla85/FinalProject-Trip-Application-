import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/model/app_user.dart';

class UserProvider {
  final _col = FirebaseFirestore.instance.collection('users'); // Users Collection

  // 회원가입
  Future<void> createUser(AppUser user) async {
    await _col.doc(user.uid).set(user.toMap()); 
  }

  // 업데이트
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _col.doc(uid).update(data);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _col.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AppUser.fromMap(snap.data()!, snap.id);
    });
  }
}

/// ✅ FirebaseAuth 인스턴스 Provider
final firebaseAuthProvider = Provider<fa.FirebaseAuth>((ref) {
  return fa.FirebaseAuth.instance;
});

/// ✅ 현재 로그인한 Auth 유저 Provider (즉시 접근용)
final currentUserProvider = Provider<fa.User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

/// ✅ 로그인 상태 감지 Provider (User? 반환)
final authStateProvider = StreamProvider<fa.User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// ✅ UserRepository Provider
final userProvider = Provider<UserProvider>((ref) {
  return UserProvider();
});

/// ✅ Firestore에서 내 users/{uid} 문서 실시간 구독
final userStreamProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  // 로그인 안 된 경우
  final user = authState.asData?.value;
  if (user == null) {
    return const Stream.empty();
  }

  final repo = ref.watch(userProvider);
  return repo.watchUser(user.uid);
});
