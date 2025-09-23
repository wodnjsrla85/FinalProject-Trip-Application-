// lib/ui/widgets/booking_lineplot_syncfusion.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class BookingLineplotSyncfusion extends StatefulWidget {
  /// 표시할 기준 월 (기본: 오늘 기준 월)
  final DateTime? month;

  /// 차트 우측 상단에 작은 "예매 페이지 >" 텍스트를 눌렀을 때의 동작
  final VoidCallback? onGoBooking;

  const BookingLineplotSyncfusion({
    super.key,
    this.month,
    this.onGoBooking,
  });

  @override
  State<BookingLineplotSyncfusion> createState() => _BookingLineplotSyncfusionState();
}

class _BookingLineplotSyncfusionState extends State<BookingLineplotSyncfusion> {
  late DateTime _monthAnchor; // 해당 월의 1일 00:00
  bool _loading = false;
  Object? _error;

  List<_DayPoint> _direct = [];
  List<_DayPoint> _package = [];

  TooltipBehavior _tooltip = TooltipBehavior(enable: true);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthAnchor = DateTime(
      widget.month?.year ?? now.year,
      widget.month?.month ?? now.month,
      1,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final start = DateTime(_monthAnchor.year, _monthAnchor.month, 1);
      final nextMonth = DateTime(_monthAnchor.year, _monthAnchor.month + 1, 1);

      // Firestore: bDate가 ISO 문자열이므로, where로 범위 필터를 쓰기 어렵다.
      // → 일단 해당 월 전부 get() 후, 클라이언트에서 파싱/필터
      // (규모 커지면 Cloud Function 집계/인덱스 컬럼 권장)
      final snap = await FirebaseFirestore.instance
          .collection('booking')
          .get();

      // 일자별 카운터
      final daysInMonth = DateUtils.getDaysInMonth(start.year, start.month);
      final directCounts = List.filled(daysInMonth, 0);
      final packageCounts = List.filled(daysInMonth, 0);

      for (final d in snap.docs) {
        final m = d.data();
        final s = (m['bDate'] ?? '').toString();
        if (s.isEmpty) continue;
        DateTime dt;
        try {
          dt = DateTime.parse(s);
        } catch (_) {
          continue;
        }
        if (dt.isBefore(start) || !dt.isBefore(nextMonth)) continue;

        final idx = dt.day - 1;
        final btype = (m['btype'] ?? '').toString();
        // "패키지" 외에는 모두 직접으로 집계
        if (btype == '패키지') {
          packageCounts[idx] += 1;
        } else {
          directCounts[idx] += 1;
        }
      }

      final direct = <_DayPoint>[];
      final pack = <_DayPoint>[];
      for (int i = 0; i < daysInMonth; i++) {
        final day = DateTime(start.year, start.month, i + 1);
        direct.add(_DayPoint(day, directCounts[i]));
        pack.add(_DayPoint(day, packageCounts[i]));
      }

      setState(() {
        _direct = direct;
        _package = pack;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    setState(() {
      _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month - 1, 1);
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month + 1, 1);
    });
    _load();
  }

  String _yyyyMM(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_error != null) {
      return Card(
        child: SizedBox(
          height: 260,
          child: Center(child: Text('오류: $_error')),
        ),
      );
    }

    final title = '월별 일자 예매량 (${_yyyyMM(_monthAnchor)})';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        child: Column(
          children: [
            // 헤더: 타이틀 / 월 변경 / 예매 페이지 이동
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: '이전 달',
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: '다음 달',
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: widget.onGoBooking,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('예매 페이지', style: TextStyle(decoration: TextDecoration.underline)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ===== Syncfusion Line Chart =====
            SizedBox(
              height: 220,
              child: SfCartesianChart(
                tooltipBehavior: _tooltip,
                legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                primaryXAxis: DateTimeAxis(
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                  dateFormat: null, // 기본 일자 포맷
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: '예매 건수'),
                  opposedPosition: true,
                  majorGridLines: const MajorGridLines(width: .5),
                ),
                series: <LineSeries<_DayPoint, DateTime>>[
                  LineSeries<_DayPoint, DateTime>(
                    name: '직접',
                    dataSource: _direct,
                    xValueMapper: (d, _) => d.day,
                    yValueMapper: (d, _) => d.count,
                    markerSettings: const MarkerSettings(isVisible: true, width: 6, height: 6),
                    dataLabelSettings: const DataLabelSettings(isVisible: false),
                    enableTooltip: true,
                  ),
                  LineSeries<_DayPoint, DateTime>(
                    name: '패키지',
                    dataSource: _package,
                    xValueMapper: (d, _) => d.day,
                    yValueMapper: (d, _) => d.count,
                    markerSettings: const MarkerSettings(isVisible: true, width: 6, height: 6),
                    dataLabelSettings: const DataLabelSettings(isVisible: false),
                    enableTooltip: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPoint {
  final DateTime day;
  final int count;
  _DayPoint(this.day, this.count);
}