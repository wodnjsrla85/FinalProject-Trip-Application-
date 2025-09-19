// lib/ui/pages/detail/airplane_end_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/airplane_end.dart';
import '../edit/airplane_end_edit_page.dart';
// ⬇️ 기존 booking_panel_by_class import 제거
// import '../../widgets/booking_panel_by_class.dart';
import '../../pages/booking/booking_rate_detail_page.dart'; // ⬅️ 상세 예매/수익 페이지로 이동

class AirplaneEndDetailPage extends StatefulWidget {
  final String docId;
  const AirplaneEndDetailPage({super.key, required this.docId});

  @override
  State<AirplaneEndDetailPage> createState() => _AirplaneEndDetailPageState();
}

class _AirplaneEndDetailPageState extends State<AirplaneEndDetailPage> {
  bool loading = true;
  Object? error;
  AirplaneEnd? _airplane;

  // ================= 성수기/비수기 판별 구간 =================
  List<_DateRange> _peakRangesForYear(int year) => [
        _DateRange(DateTime(year, 7, 15), DateTime(year, 8, 31)),
        _DateRange(DateTime(year, 12, 15), DateTime(year + 1, 1, 5)),
      ];

  bool _isPeak(DateTime d) {
    final ranges = _peakRangesForYear(d.year);
    ranges.addAll(_peakRangesForYear(d.year - 1));
    for (final r in ranges) {
      if (r.contains(d)) return true;
    }
    return false;
  }

  // ================= 운임표 =================
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

  String _distanceTypeOf(AirplaneEnd a) {
    if (a.distanceType.isNotEmpty) return a.distanceType;
    final m = a.durationMin;
    if (m <= 180) return "단거리";
    if (m <= 420) return "중거리";
    return "장거리";
  }

  String _won(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
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
          .collection('airplane_end')
          .doc(widget.docId)
          .get();

      if (!snap.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      final a = AirplaneEnd.fromJson(snap.id, data);

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
        .collection('airplane_end')
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

    final currentFareMap = _fareTable[dist]?[season] ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text('도착편 상세 - ${a.flightNo}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AirplaneEndEditPage(docId: widget.docId)),
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

          if (flightDate != null)
            _FareCard(
              season: season,
              distanceType: dist,
              fares: currentFareMap,
              won: _won,
            ),

          const SizedBox(height: 12),
          const Divider(),

          // ⬇️ 등급별 예매/수익은 전용 상세 페이지로 이동
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('예매 현황 · 수익(좌석등급별)'),
            subtitle: const Text('상세 페이지에서 등급별 예매 좌석·수익을 확인하세요'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingRateDetailPage(
                    flightId: widget.docId,
                    collection: 'airplane_end',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===== 유틸 클래스들 =====
class _DateRange {
  final DateTime start;
  final DateTime end;
  _DateRange(this.start, this.end);
  bool contains(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
}

class _FareCard extends StatelessWidget {
  final String season;
  final String distanceType;
  final Map<String, int> fares;
  final String Function(int) won;

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