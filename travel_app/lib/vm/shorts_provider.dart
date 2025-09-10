import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/Model/ShortMeta.dart'; // ShortMeta & VideosRepository(업데이트 버전)

// ─────────────────────────────────────────────────────────────────────────────
// 기본 Provider들
// ─────────────────────────────────────────────────────────────────────────────
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Firestore를 (default)기본DB로 연결
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance; // <<<
});

/// Storage
final storageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// 로그인 / 비로그인(익명) 
final currentUidProvider = Provider<String>((ref) {
  return ref.watch(authProvider).currentUser?.uid ?? 'anonymous';
  // 로그인 상태에서는 Uid노출, 미로그인 시 익명 로그인 
});

/// 레포지토리 (shorts 컬렉션을 다루도록 구현됨)
final videosRepoProvider = Provider<VideosRepository>((ref) {  
  return VideosRepository(ref.read(firestoreProvider), ref.read(storageProvider));
  // VideosRepository : Storage 업로드 + Firestore(shorts) 저장을 수행.
});

// ─────────────────────────────────────────────────────────────────────────────
// Streams
// ─────────────────────────────────────────────────────────────────────────────

/// shorts 리스트(최신순) ->  SDate 최신순으로 실시간 구독
final shortsStreamProvider = StreamProvider<List<ShortMeta>>((ref) {
  return ref.watch(videosRepoProvider).watchShorts();  // model에 watchShorts
});

/// (호환용) 예전 UI에서 videosStreamProvider를 쓰고 있으면 그대로 연결
final videosStreamProvider = shortsStreamProvider;

// ─────────────────────────────────────────────────────────────────────────────
// 업로드 진행률
// ─────────────────────────────────────────────────────────────────────────────
final uploadProgressProvider = StateProvider<double?>((ref) => null);
// 0.0 ~ 1.0 사이 진행률.
// 업로드 끝나면 null 로 초기화 → LinearProgressIndicator 숨김.

// ─────────────────────────────────────────────────────────────────────────────
/* 업로드 파라미터 */
// ─────────────────────────────────────────────────────────────────────────────
class UploadShortParams {
  final File file;         // 업로드할 파일
  final String title;      // STitle
  final String country;    // SCountry
  final String? docId;     // 특정 문서를 갱신하려면 지정(없으면 새 문서 생성)
  const UploadShortParams({
    required this.file,
    required this.title,
    required this.country,
    this.docId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
/* 업로드 + Firestore 저장 (권장) */
// ─────────────────────────────────────────────────────────────────────────────
final uploadShortProvider =
    FutureProvider.family<void, UploadShortParams>((ref, p) async {
  final auth = ref.read(authProvider);
  if (auth.currentUser == null) {
    await auth.signInAnonymously(); // 테스트용 익명 로그인
  }
  final uid = ref.read(currentUidProvider);

  try {
    final repo = ref.read(videosRepoProvider);

    // Storage 업로드 + Firestore(shorts) 저장 (레포지토리에서 처리)
    await repo.uploadShort(
      file: p.file,
      fileName: p.file.path.split('/').last,
      ownerUid: uid,
      title: p.title,
      country: p.country,
      docId: p.docId, // null이면 새 문서 생성
      onProgress: (pct) =>
          ref.read(uploadProgressProvider.notifier).state = pct,
    );
  } finally {
    ref.read(uploadProgressProvider.notifier).state = null;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
/* (선택) 호환용 래퍼: 파일만 받아 업로드. 제목/나라는 기본값 */
//    기존 코드에서 uploadVideoProvider(file)만 호출하던 경우를 위해 제공.
//    새 UI에서는 uploadShortProvider(UploadShortParams(...))를 사용하세요.
// ─────────────────────────────────────────────────────────────────────────────
final uploadVideoProvider = FutureProvider.family<void, File>((ref, file) async {
  await ref
      .read(
        uploadShortProvider(
          UploadShortParams(
            file: file,
            title: 'Untitled',
            country: 'Unknown',
          ),
        ).future,
      )
      .catchError((_) {}); // 에러 처리는 호출부에서 SnackBar 등으로
});
