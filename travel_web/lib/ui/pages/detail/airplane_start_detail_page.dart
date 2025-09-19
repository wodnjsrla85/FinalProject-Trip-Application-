// lib/ui/pages/detail/airplane_start_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/airplane_start.dart';
import '../edit/airplane_start_edit_page.dart';
import '../../widgets/booking_panel_by_class.dart';

class AirplaneStartDetailPage extends StatefulWidget {
  final String docId;
  const AirplaneStartDetailPage({super.key, required this.docId});

  @override
  State<AirplaneStartDetailPage> createState() => _AirplaneStartDetailPageState();
}

class _AirplaneStartDetailPageState extends State<AirplaneStartDetailPage> {
  bool loading = true;
  Object? error;
  AirplaneStart? _airplane; // 로딩 후 모델 보관

  // ===================== 성수기/비수기 판별 설정 =====================
  // 필요 시 아래 기간들을 수정하면 됨.
  // - 여름 성수기: 7/15 ~ 8/31
  // - 겨울 성수기: 12/15 ~ 익년 1/5 (연도 걸침 처리)
  // - 추가/수정 가능: 예) 5/3~5/7, 9/28~10/3 등
  List<_DateRange> _peakRangesForYear(int year) => [
        _DateRange(DateTime(year, 7, 15), DateTime(year, 8, 31)),
        _DateRange(DateTime(year, 12, 15), DateTime(year + 1, 1, 5)),
      ];

  bool _isPeak(DateTime d) {
    final ranges = _peakRangesForYear(d.year);
    // 연도 걸치는 구간(예: 12/15 ~ 다음해 1/5)도 정상 처리하려면
    // d.year-1 구간도 같이 체크
    ranges.addAll(_peakRangesForYear(d.year - 1));
    for (final r in ranges) {
      if (r.contains(d)) return true;
    }
    return false;
  }

  // ===================== 운임표(요청 스펙 그대로) =====================
  static const Map<String, Map<String, Map<String, int>>> _fareTable = {
    "단거리": {
      "비수기": {"이코노미": 105000, "프리미엄이코노미": 171750, "비즈니스": 330000, "퍼스트": 864000},
      "성수기": {"이코노미": 210000, "프리미엄이코노미": 343500, "비즈니스": 660000, "퍼스트": 1728000},
    },
    "중거리": {
      "비수기": {"이코노미": 105000, "프리미엄이코노미": 171750, "비즈니스": 330000, "퍼스트": 864000},
      "성수기": {"이코노미": 150000, "프리미엄이코노미": 217500, "비즈니스": 300000, "퍼스트": 960000},
    },
    "장거리": {
      "비수기": {"이코노미": 600000, "프리미엄이코노미": 985000, "비즈니스": 1900000, "퍼스트": 5000000},
      "성수기": {"이코노미": 925000, "프리미엄이코노미": 1523750, "비즈니스": 2950000, "퍼스트": 7800000},
    },
  };

  // 거리구분 보조 (문서에 distanceType 있으면 우선 사용, 없으면 durationMin으로 판정)
  String _distanceTypeOf(AirplaneStart a) {
    if (a.distanceType.isNotEmpty) return a.distanceType;
    final m = a.durationMin;
    if (m <= 180) return "단거리";
    if (m <= 420) return "중거리";
    return "장거리";
  }

  // 숫자 콤마 포맷 (intl 없이 간단 구현)
  String _won(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return '${buf.toString()}원';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('airplane_start')
          .doc(widget.docId)
          .get();

      if (!snap.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      final a = AirplaneStart.fromJson(snap.id, data);

      setState(() {
        _airplane = a;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 항공편을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    await FirebaseFirestore.instance
        .collection('airplane_start')
        .doc(widget.docId)
        .delete();

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(body: Center(child: Text('오류: $error')));
    }
    final a = _airplane!;

    // ===== 성수기/비수기 판별 =====
    DateTime? flightDate;
    try {
      final p = a.flightDate.split('-');
      flightDate = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {}
    final season = (flightDate != null && _isPeak(flightDate)) ? '성수기' : '비수기';
    final dist = _distanceTypeOf(a);

    // 현재 날짜/거리 기준 운임표
    final currentFareMap = _fareTable[dist]?[season] ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text('출발편 상세 - ${a.flightNo}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AirplaneStartEditPage(docId: widget.docId)),
              );
              if (updated == true) _load();
            },
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${a.origin} → ${a.destination}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('항공사: ${a.airline}'),
          Text('기종: ${a.aircraft}'),
          Text('운항일자: ${a.flightDate}'),
          Text('출발: ${a.departureTime}'),
          Text('도착: ${a.arrivalDate} ${a.arrivalTime}'),
          Text('예상 소요: ${a.durationHHMM} (${a.durationMin}분)'),
          Text('좌석: ${a.totalSeats}'),
          Text('상태: ${a.status} / ${a.isDirect ? '직항' : a.directType}'),
          const SizedBox(height: 12),

          // ====== 현재 날짜 기준 운임 정보 카드 ======
          if (flightDate != null)
            _FareCard(
              season: season,
              distanceType: dist,
              fares: currentFareMap,
              won: _won,
            ),
          if (flightDate == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('운항일자를 파싱할 수 없어 운임표를 표시하지 못했습니다.'),
            ),

          const SizedBox(height: 12),
          const Divider(),
          // 좌석 등급별 집계 + 이메일 검색 패널
          BookingPanelByClass(flightDocId: widget.docId),
        ],
      ),
    );
  }
}

// 간단한 날짜 구간 클래스
class _DateRange {
  final DateTime start; // 포함
  final DateTime end;   // 포함
  _DateRange(this.start, this.end);
  bool contains(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
}

// 운임 정보 카드 위젯
class _FareCard extends StatelessWidget {
  final String season;                // '성수기' or '비수기'
  final String distanceType;          // '단거리' / '중거리' / '장거리'
  final Map<String, int> fares;       // { '이코노미': 105000, ... }
  final String Function(int) won;     // 금액 포맷터

  const _FareCard({
    required this.season,
    required this.distanceType,
    required this.fares,
    required this.won,
  });

  @override
  Widget build(BuildContext context) {
    final order = const ['이코노미', '프리미엄이코노미', '비즈니스', '퍼스트'];
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('평균 운임 (${distanceType} · $season)',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: order.map((cls) {
                final price = fares[cls] ?? 0;
                return Chip(
                  label: Text('$cls: ${won(price)}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}