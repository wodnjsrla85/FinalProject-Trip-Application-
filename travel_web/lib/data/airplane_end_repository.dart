import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/airplane_end.dart';

class AirplaneEndRepository {
  static String collectionName = 'airplane_end';

  final _ref = FirebaseFirestore.instance
      .collection(collectionName)
      .withConverter<AirplaneEnd>(
        fromFirestore: (snap, _) => AirplaneEnd.fromJson(snap.id, snap.data()!),
        toFirestore: (obj, _) => {}, // 쓰기는 add/update에서 Map 직접 사용
      );

  Future<AirplaneEnd?> fetchById(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  /// 도착지(destination = 기본 ICN), 출발지(origin) 선택, 직항 필터.
  Query<AirplaneEnd> baseQuery({
    String? destination,
    String? origin,
    bool? directOnly,
  }) {
    Query<AirplaneEnd> q = _ref
        .where('상태', isEqualTo: '운행')
        .where('목적지', isEqualTo: destination);
        // 필요 시 .orderBy('출발시간') 등 추가

    if (origin != null && origin.isNotEmpty) {
      q = q.where('출발지', isEqualTo: origin);
    }
    if (directOnly == true) {
      q = q.where('직항여부', isEqualTo: 1);
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
}