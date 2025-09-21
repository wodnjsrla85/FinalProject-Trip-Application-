import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/airplane_start.dart';

class AirplaneStartRepository {
  static const collectionName = 'airplane_start';

  final _ref = FirebaseFirestore.instance
      .collection(collectionName)
      .withConverter<AirplaneStart>(
        fromFirestore: (snap, _) =>
            AirplaneStart.fromJson(snap.id, snap.data() ?? {}),
        toFirestore: (obj, _) => {}, // 쓰기는 별도 Map 사용
      );

  Future<AirplaneStart?> fetchById(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  /// 기본 조회 쿼리
  /// - status: 기본값 '운행 완료' (데이터 스키마에 맞춤)
  /// - origin/dest/date는 있으면 where 추가
  /// - directOnly == true 면 직항여부 == 1
  /// - flightNoPrefix가 있으면 '운항편명' orderBy + startAt/endBefore로 접두사 검색
  Query<AirplaneStart> baseQuery({
    String status = '운행 완료',
    String? origin,
    String? dest,
    String? date,            // 'YYYY-MM-DD'
    bool? directOnly,
    String? flightNoPrefix,  // 편명 접두사 (예: 'KE', 'JL')
    int? limit,
  }) {
    Query<AirplaneStart> q = _ref;

    if (status.isNotEmpty) {
      q = q.where('상태', isEqualTo: status);
    }
    if (origin != null && origin.isNotEmpty) {
      q = q.where('출발지', isEqualTo: origin);
    }
    if (dest != null && dest.isNotEmpty) {
      q = q.where('목적지', isEqualTo: dest);
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

  Future<QuerySnapshot<AirplaneStart>> fetchPage({
    required Query<AirplaneStart> query,
    DocumentSnapshot<AirplaneStart>? last,
    int limit = 20,
  }) {
    final q = last == null ? query.limit(limit)
                           : query.startAfterDocument(last).limit(limit);
    return q.get();
  }

  /// 여러 id로 일괄 조회 (whereIn 10개 제한 주의 → 청크 처리 필요시 밖에서)
  Future<List<AirplaneStart>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _ref.where(FieldPath.documentId, whereIn: ids).get();
    return snap.docs.map((d) => d.data()).whereType<AirplaneStart>().toList();
  }
}