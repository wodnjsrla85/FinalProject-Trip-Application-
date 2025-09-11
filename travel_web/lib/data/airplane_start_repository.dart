import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/airplane_start.dart';

class AirplaneStartRepository {
  static String collectionName = 'airplane_start';

  final _ref = FirebaseFirestore.instance
      .collection(collectionName)
      .withConverter<AirplaneStart>(
        fromFirestore: (snap, _) => AirplaneStart.fromJson(snap.id, snap.data()!),
        toFirestore: (obj, _) => {}, // 쓰기는 add/update에서 Map 직접 사용
      );

  Future<AirplaneStart?> fetchById(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  /// 출발지(origin), 상태=운행 고정. 목적지/직항 필터 옵션.
  Query<AirplaneStart> baseQuery({
    String origin = 'ICN',
    String? dest,
    bool? directOnly, // true 면 직항여부=1, null이면 무시
  }) {
    Query<AirplaneStart> q = _ref
        .where('상태', isEqualTo: '운행')
        .where('출발지', isEqualTo: origin);
        // 정렬이 필요하면 .orderBy('출발시간') 등 추가

    if (dest != null && dest.isNotEmpty) {
      q = q.where('목적지', isEqualTo: dest);
    }
    if (directOnly == true) {
      q = q.where('직항여부', isEqualTo: 1);
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
}