import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/airplane_end.dart';

class AirplaneEndRepository {
  static const collectionName = 'airplane_end';

  final _ref = FirebaseFirestore.instance
      .collection(collectionName)
      .withConverter<AirplaneEnd>(
        fromFirestore: (snap, _) =>
            AirplaneEnd.fromJson(snap.id, snap.data() ?? {}),
        toFirestore: (obj, _) => {},
      );

  Future<AirplaneEnd?> fetchById(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  /// 기본 조회 쿼리
  /// - status: 기본값 '운행 완료'
  /// - destination/origin/date 조건부 추가
  /// - flightNoPrefix 접두사 검색 지원
  Query<AirplaneEnd> baseQuery({
    String status = '운행 완료',
    String? destination,
    String? origin,
    String? date,            // 'YYYY-MM-DD'
    bool? directOnly,
    String? flightNoPrefix,  // 편명 접두사
    int? limit,
  }) {
    Query<AirplaneEnd> q = _ref;

    if (status.isNotEmpty) {
      q = q.where('상태', isEqualTo: status);
    }
    if (destination != null && destination.isNotEmpty) {
      q = q.where('목적지', isEqualTo: destination);
    }
    if (origin != null && origin.isNotEmpty) {
      q = q.where('출발지', isEqualTo: origin);
    }
    if (date != null && date.isNotEmpty) {
      q = q.where('운항일자', isEqualTo: date);
    }
    if (directOnly == true) {
      q = q.where('직항여부', isEqualTo: 1);
    }
    if (flightNoPrefix != null && flightNoPrefix.isNotEmpty) {
      final last = flightNoPrefix.codeUnitAt(flightNoPrefix.length - 1);
      final next = String.fromCharCode(last + 1);
      final end = flightNoPrefix.substring(0, flightNoPrefix.length - 1) + next;
      q = q.orderBy('운항편명').startAt([flightNoPrefix]).endBefore([end]);
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }
    return q;
  }

  Future<QuerySnapshot<AirplaneEnd>> fetchPage({
    required Query<AirplaneEnd> query,
    DocumentSnapshot<AirplaneEnd>? last,
    int limit = 20,
  }) {
    final q = last == null ? query.limit(limit)
                           : query.startAfterDocument(last).limit(limit);
    return q.get();
  }

  Future<List<AirplaneEnd>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _ref.where(FieldPath.documentId, whereIn: ids).get();
    return snap.docs.map((d) => d.data()).whereType<AirplaneEnd>().toList();
  }
}