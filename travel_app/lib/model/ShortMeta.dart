// Model/VideoRepository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firestore 'shorts' 문서 스키마에 맞춘 모델
class ShortMeta {
  final String id;            // 문서 ID (SId와 동일하게 관리)
  final DateTime? sDate;      // SDate
  final String sId;           // SId (문서 ID를 그대로 저장)
  final int sLikeCount;       // SLike_count
  final String sTitle;        // STitle
  final String sVideo;        // SVideo (다운로드 URL)
  final String sPath;         // SPath (Storage 경로)
  final String sCountry;      // SCountry
  final String uEmail;        // UEmail

  ShortMeta({
    required this.id,
    required this.sDate,
    required this.sId,
    required this.sLikeCount,
    required this.sTitle,
    required this.sVideo,
    required this.sPath,
    required this.sCountry,
    required this.uEmail,
  });

  factory ShortMeta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return ShortMeta(
      id: doc.id,
      sDate: (d['SDate'] as Timestamp?)?.toDate(),
      sId: (d['SId'] ?? doc.id) as String,
      sLikeCount: _toInt(d['SLike_count'] ?? 0),
      sTitle: (d['STitle'] ?? '') as String,
      sVideo: (d['SVideo'] ?? '') as String,
      sPath: (d['SPath'] ?? '') as String, 
      sCountry: (d['SCountry'] ?? '') as String,
      uEmail: (d['UEmail'] ?? '') as String,
    );
  }
}

class VideosRepository {
  final FirebaseFirestore db;     // !!! viewModel.dart에서 databaseId='travel' 로 주입
  final FirebaseStorage storage;
  VideosRepository(this.db, this.storage);

  /// shorts 리스트 실시간 구독 (최신순)
  Stream<List<ShortMeta>> watchShorts() {
    return db
        .collection('shorts')
        .orderBy('SDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ShortMeta.fromDoc(d)).toList());
  }

  /// 파일 업로드 + shorts 문서 생성/갱신
  /// - docId가 있으면 해당 문서 갱신(merge)
  /// - 없으면 새 문서 생성
  Future<String> uploadShort({
  required File file,
  required String fileName,
  required String ownerUid,                // Storage 경로용
  String? userEmail,                      // UEmail 저장
  String? docId,                          // 지정 시 해당 문서 업데이트
  String title = '',                      // STitle
  String country = '',
  void Function(double pct)? onProgress,
}) async {
  // 1) Storage 업로드
  final ref = storage
      .ref()
      .child('videos/$ownerUid/${DateTime.now().millisecondsSinceEpoch}_$fileName');

  final task = ref.putFile(
    file,
    SettableMetadata(contentType: 'video/mp4'), // mp4 기준
  );

  task.snapshotEvents.listen((s) {
    if (s.totalBytes > 0 && onProgress != null) {
      onProgress(s.bytesTransferred / s.totalBytes);
    }
  });

  final snap = await task;
  final url = await snap.ref.getDownloadURL();
  final path = snap.ref.fullPath;   // Storage 내부 경로

  // 2) Firestore 'shorts'에 저장
  final col = db.collection('shorts');
  final docRef = (docId != null && docId.isNotEmpty) ? col.doc(docId) : col.doc();

  await docRef.set({
    'SVideo'      : url,       // 다운로드 URL
    'SPath'       : path,      // Storage 내부 경로 저장
    'STitle'      : title,
    'SCountry'    : country,
    'SId'         : docRef.id,
    'UEmail'      : userEmail ?? '',
    'SDate'       : FieldValue.serverTimestamp(),
    'SLike_count' : FieldValue.increment(0),
  }, SetOptions(merge: true));

  return url;
}
}