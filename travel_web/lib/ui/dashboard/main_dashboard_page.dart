import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// 항공편 탭 페이지(출발/도착)
import 'package:travel_web/ui/dashboard_page.dart';
// 예매 확인(리스트/상세로 연결)
import 'package:travel_web/ui/pages/booking/booking_rate_page.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  bool _loading = true;
  Object? _error;

  // 월 anchor
  late DateTime _currentMonth;
  late String _monthLabel;

  // KPI
  int _totalBookings = 0; // 이달 결제완료 예약 수
  int _totalRevenue = 0;  // 이달 결제완료 총액
  final _wonFmt = NumberFormat.decimalPattern('ko_KR');
  String _won(num v) => '₩${_wonFmt.format(v)}';

  // 일별 총 예약(결제완료)
  List<_DayPoint> _daily = [];

  // 연간 월별(결제완료)
  List<_MonthPoint> _monthly = [];

  // 성별/나이
  List<_SexSlice> _sexSlices = const [];
  List<_AgeBucket> _ageBuckets = const [];

  // 문의(inquery)
  _InquerySummary _inqSummary = const _InquerySummary();
  List<_InqueryItem> _inqueries = const [];

  // 노선 Top5
  List<_RouteStat> _topRoutes = [];

  // 차트 tooltip
  late TooltipBehavior _tooltip;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _monthLabel = DateFormat('yyyy.MM').format(_currentMonth);
    _tooltip = TooltipBehavior(enable: true, canShowMarker: true);
    _loadAll();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _currentMonth = DateTime(picked.year, picked.month, 1);
        _monthLabel = DateFormat('yyyy.MM').format(_currentMonth);
      });
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadBookingsThisMonth(), // KPI / 일별 / Top5
        _loadBookingsThisYear(),  // 연간 월별
        _loadUsers(),             // 성별/나이
        _loadInqueries(),         // 문의 집계 + 최근
      ]);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  // ─────────────────────────────
  // Firestore helpers
  // ─────────────────────────────
  int _asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

  String _safeStr(dynamic v) => (v ?? '').toString();

  DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    // ISO or "YYYY-MM-DD"
    final s = _safeStr(v);
    final dt = DateTime.tryParse(s);
    if (dt != null) return dt;
    // "YYYY-MM-DD"만 온 경우
    if (s.length >= 10) {
      final y = int.tryParse(s.substring(0, 4)) ?? 1970;
      final m = int.tryParse(s.substring(5, 7)) ?? 1;
      final d = int.tryParse(s.substring(8, 10)) ?? 1;
      return DateTime(y, m, d);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // 이번 달 [bDate] 범위
  (String start, String endExclusive, int daysInMonth) _monthRange() {
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final endExclusive = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final sStart = DateFormat('yyyy-MM-dd').format(start);
    final sEnd = DateFormat('yyyy-MM-dd').format(endExclusive);
    final days = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    return (sStart, sEnd, days);
  }

  // 올해 [bDate] 범위
  (String start, String endExclusive) _yearRange() {
    final y = _currentMonth.year;
    final start = DateFormat('yyyy-MM-dd').format(DateTime(y, 1, 1));
    final end   = DateFormat('yyyy-MM-dd').format(DateTime(y + 1, 1, 1));
    return (start, end);
  }

  // 일자 문자열 "YYYY-MM-DD" → 0-based day index (같은 달만)
  int? _dayIndexInMonth(String s) {
    if (s.length < 10) return null;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(5, 7));
    final d = int.tryParse(s.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    if (y != _currentMonth.year || m != _currentMonth.month) return null;
    return d - 1;
  }

  // ─────────────────────────────
  // Bookings (이달: KPI/일별/Top5)
  // ─────────────────────────────
  Future<void> _loadBookingsThisMonth() async {
    final (startStr, endStr, dim) = _monthRange();

    final daily = List.generate(dim, (i) {
      final d = DateTime(_currentMonth.year, _currentMonth.month, i + 1);
      return _DayPoint(d, DateFormat('d일').format(d), 0);
    });

    final qs = await FirebaseFirestore.instance
        .collection('booking')
        .where('bDate', isGreaterThanOrEqualTo: startStr)
        .where('bDate', isLessThan: endStr)
        .orderBy('bDate') // 단일 필드 정렬(인덱스 불필요)
        .get();

    int totalCount = 0;
    int totalRevenue = 0;

    // 노선 집계(패키지 제외 → airplane_* 문서와 연결 가능)
    final Map<String, int> flightCountById = {};

    for (final d in qs.docs) {
      final m = d.data();
      if (_safeStr(m['bState']) != '결제완료') continue;

      final idx = _dayIndexInMonth(_safeStr(m['bDate']));
      if (idx == null || idx < 0 || idx >= daily.length) continue;

      daily[idx].count += 1;
      totalCount += 1;
      totalRevenue += _asInt(m['aPrice']);

      if (_safeStr(m['what']) != '패키지') {
        final fid = _safeStr(m['aid']);
        if (fid.isNotEmpty) {
          flightCountById[fid] = (flightCountById[fid] ?? 0) + 1;
        }
      }
    }

    final topRoutes = await _resolveTopRoutes(flightCountById);

    _daily = daily;
    _totalBookings = totalCount;
    _totalRevenue = totalRevenue;
    _topRoutes = topRoutes;
  }

  // Bookings (올해: 월별 막대)
  Future<void> _loadBookingsThisYear() async {
    final (startStr, endStr) = _yearRange();

    final monthly = List.generate(
      12,
      (i) => _MonthPoint(i + 1, '${i + 1}월', 0),
    );

    final qs = await FirebaseFirestore.instance
        .collection('booking')
        .where('bDate', isGreaterThanOrEqualTo: startStr)
        .where('bDate', isLessThan: endStr)
        .orderBy('bDate')
        .get();

    for (final d in qs.docs) {
      final m = d.data();
      if (_safeStr(m['bState']) != '결제완료') continue;

      final s = _safeStr(m['bDate']); // "YYYY-MM-DD"
      if (s.length < 7) continue;
      final mm = int.tryParse(s.substring(5, 7));
      if (mm == null || mm < 1 || mm > 12) continue;

      monthly[mm - 1].count += 1;
    }

    _monthly = monthly;
  }

  // flight 메타 resolve
  Future<List<_RouteStat>> _resolveTopRoutes(Map<String, int> counts) async {
    if (counts.isEmpty) return [];

    Future<Map<String, Map<String, dynamic>>> fetchMany(
      String collection,
      List<String> ids,
    ) async {
      final Map<String, Map<String, dynamic>> out = {};
      const chunk = 10;
      for (var i = 0; i < ids.length; i += chunk) {
        final part = ids.sublist(i, min(i + chunk, ids.length));
        final qs = await FirebaseFirestore.instance
            .collection(collection)
            .where(FieldPath.documentId, whereIn: part)
            .get();
        for (final d in qs.docs) {
          out[d.id] = d.data();
        }
      }
      return out;
    }

    final ids = counts.keys.toList();
    final startMap = await fetchMany('airplane_start', ids);
    final endMap = await fetchMany('airplane_end', ids);

    final list = <_RouteStat>[];
    for (final e in counts.entries) {
      final fid = e.key;
      final c = e.value;
      final meta = startMap[fid] ?? endMap[fid];

      String origin = '미상';
      String dest = '미상';
      if (meta != null) {
        final o = _safeStr(meta['출발지']);
        final t = _safeStr(meta['목적지']);
        if (o.isNotEmpty) origin = o;
        if (t.isNotEmpty) dest = t;
      }
      list.add(_RouteStat(fid: fid, routeLabel: '$origin → $dest', count: c));
    }
    list.sort((a, b) => b.count.compareTo(a.count));
    return list.take(5).toList();
  }

  // Users (성별/나이)
  Future<void> _loadUsers() async {
    final qs = await FirebaseFirestore.instance.collection('users').get();

    int male = 0, female = 0, other = 0;
    final buckets = <_AgeBucket>[
      _AgeBucket('0–9', 0, 9),
      _AgeBucket('10–19', 10, 19),
      _AgeBucket('20–29', 20, 29),
      _AgeBucket('30–39', 30, 39),
      _AgeBucket('40–49', 40, 49),
      _AgeBucket('50–59', 50, 59),
      _AgeBucket('60–69', 60, 69),
      _AgeBucket('70+', 70, 200),
    ];

    for (final d in qs.docs) {
      final m = d.data();

      final sex = _safeStr(m['sex']).trim();
      if (sex == '남자') male++;
      else if (sex == '여자') female++;
      else other++;

      final age = _asInt(m['age']);
      for (final b in buckets) {
        if (age >= b.min && age <= b.max) {
          b.count++;
          break;
        }
      }
    }

    _sexSlices = [
      _SexSlice('남자', male),
      _SexSlice('여자', female),
      _SexSlice('기타', other),
    ];
    _ageBuckets = buckets;
  }

  // Inqueries (복합 인덱스 없이 동작하도록 분리)
  Future<void> _loadInqueries() async {
    // 1) 요약: where만
    final summaryQs = await FirebaseFirestore.instance
        .collection('inquery')
        .where('to', isEqualTo: '항공사')
        .get();

    int total = 0, completed = 0, pending = 0;
    for (final d in summaryQs.docs) {
      total++;
      final state = _safeStr(d.data()['state']);
      if (state == '답변완료') completed++;
      else pending++;
    }

    // 2) 최신 목록: orderBy만 → 이후 필터
    final latestQs = await FirebaseFirestore.instance
        .collection('inquery')
        .orderBy('date', descending: true)
        .limit(50)
        .get();

    final items = <_InqueryItem>[];
    for (final d in latestQs.docs) {
      final m = d.data();
      if (_safeStr(m['to']) != '항공사') continue;
      items.add(
        _InqueryItem(
          id: d.id,
          title: _safeStr(m['title']),
          email: _safeStr(m['uEmail']),
          status: _safeStr(m['state']),
          createdAt: _asDate(m['date']),
        ),
      );
      if (items.length >= 12) break;
    }

    _inqSummary = _InquerySummary(total: total, completed: completed, pending: pending);
    _inqueries = items;
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('항공 대시보드'),
        actions: [
          // 항공편 탭 페이지로 이동(출발/도착 탭)
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            },
            icon: const Icon(Icons.flight, size: 18),
            label: const Text('항공편'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
              ? Center(child: Text('로드 오류: $_error'))
              : _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1200;
        final isMedium = constraints.maxWidth >= 900 && constraints.maxWidth < 1200;
        final crossAxis = isWide ? 3 : (isMedium ? 2 : 1);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1) 상단 KPI + 월 선택
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _KpiCard(
                          title: '이달 예매량(결제완료)',
                          value: '${_wonFmt.format(_totalBookings)}건',
                          icon: Icons.receipt_long,
                          color: Colors.indigo,
                        ),
                        _KpiCard(
                          title: '이달 수익',
                          value: _won(_totalRevenue),
                          icon: Icons.attach_money,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('집계 월 선택', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: _pickMonth,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_monthLabel),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2) 메인 그리드: 일별(라인) → 연간(막대) → TOP5 (요청: TOP5를 연간 오른쪽에)
              _ResponsiveGrid(
                crossAxisCount: crossAxis,
                children: [
                  _Panel(
                    title: '월간 · 일별 예매 추이 (전체)',
                    trailing: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookingRatePage()),
                        );
                      },
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('예매 통계 보기'),
                    ),
                    child: SizedBox(
                      height: 260,
                      child: SfCartesianChart(
                        tooltipBehavior: _tooltip,
                        primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                        primaryYAxis: const NumericAxis(majorGridLines: MajorGridLines(width: 1), decimalPlaces: 0),
                        series: <CartesianSeries<_DayPoint, String>>[
                          LineSeries<_DayPoint, String>(
                            name: '예약수',
                            dataSource: _daily,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.count,
                            markerSettings: const MarkerSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Panel(
                    title: '연간 · 월별 예매 추이 (결제완료)',
                    subtitle: '${_currentMonth.year}년',
                    child: SizedBox(
                      height: 260,
                      child: SfCartesianChart(
                        tooltipBehavior: _tooltip,
                        primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                        primaryYAxis: const NumericAxis(majorGridLines: MajorGridLines(width: 1), decimalPlaces: 0),
                        series: <CartesianSeries<_MonthPoint, String>>[
                          ColumnSeries<_MonthPoint, String>(
                            name: '예약수',
                            dataSource: _monthly,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.count,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ✅ TOP5를 같은 그리드 라인에 배치 — 3열이면 연간의 "오른쪽"에 위치
                  _Panel(
                    title: '노선별 예약 TOP 5',
                    subtitle: '이번 달 결제완료 + 항공편 예약 기준 (패키지 제외)',
                    child: _RouteTop5List(
                      items: _topRoutes,
                      onItemTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingRatePage()));
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3) 하단: 성별/나이 + 문의현황
              _ResponsiveGrid(
                crossAxisCount: crossAxis,
                children: [
                  _Panel(
                    title: '성별 분포',
                    child: SizedBox(
                      height: 260,
                      child: SfCircularChart(
                        legend: const Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                        tooltipBehavior: _tooltip,
                        series: <CircularSeries<_SexSlice, String>>[
                          PieSeries<_SexSlice, String>(
                            dataSource: _sexSlices,
                            xValueMapper: (s, _) => s.label,
                            yValueMapper: (s, _) => s.count,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Panel(
                    title: '나이 분포 (명)',
                    child: SizedBox(
                      height: 260,
                      child: SfCartesianChart(
                        tooltipBehavior: _tooltip,
                        primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                        primaryYAxis: const NumericAxis(majorGridLines: MajorGridLines(width: 1), decimalPlaces: 0),
                        series: <CartesianSeries<_AgeBucket, String>>[
                          ColumnSeries<_AgeBucket, String>(
                            name: '인원',
                            dataSource: _ageBuckets,
                            xValueMapper: (b, _) => b.label,
                            yValueMapper: (b, _) => b.count,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Panel(
                    title: '문의 현황',
                    subtitle: 'to = 항공사',
                    child: SizedBox(
                      height: 260,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatusChip(label: '전체', count: _inqSummary.total, color: Colors.blue),
                              _StatusChip(label: '답변완료', count: _inqSummary.completed, color: Colors.green),
                              _StatusChip(label: '미완료', count: _inqSummary.pending, color: Colors.red),
                            ],
                          ),
                          const Divider(height: 16),
                          Expanded(child: _InqueryList(items: _inqueries)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────
// 모델
// ─────────────────────────────
class _DayPoint {
  final DateTime day;
  final String label; // "1일" …
  int count;
  _DayPoint(this.day, this.label, this.count);
}

class _MonthPoint {
  final int month;    // 1~12
  final String label; // "1월"
  int count;
  _MonthPoint(this.month, this.label, this.count);
}

class _RouteStat {
  final String fid;
  final String routeLabel;
  final int count;
  _RouteStat({required this.fid, required this.routeLabel, required this.count});
}

class _SexSlice {
  final String label;
  final int count;
  const _SexSlice(this.label, this.count);
}

class _AgeBucket {
  final String label;
  final int min;
  final int max;
  int count;
  _AgeBucket(this.label, this.min, this.max, {this.count = 0});
}

class _InquerySummary {
  final int total;
  final int completed;
  final int pending;
  const _InquerySummary({this.total = 0, this.completed = 0, this.pending = 0});
}

class _InqueryItem {
  final String id;
  final String title;
  final String email;
  final String status;
  final DateTime createdAt;
  _InqueryItem({
    required this.id,
    required this.title,
    required this.email,
    required this.status,
    required this.createdAt,
  });
}

// ─────────────────────────────
// 공용 위젯
// ─────────────────────────────
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  const _Panel({
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteTop5List extends StatelessWidget {
  final List<_RouteStat> items;
  final VoidCallback? onItemTap;
  const _RouteTop5List({required this.items, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(height: 240, child: Center(child: Text('데이터 없음')));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 8),
      itemBuilder: (context, i) {
        final r = items[i];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade300,
            child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(r.routeLabel),
          subtitle: Text('예약: ${r.count}건'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onItemTap, // 탭 → 예매 확인 페이지
        );
      },
    );
  }
}

class _InqueryList extends StatelessWidget {
  final List<_InqueryItem> items;
  const _InqueryList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('문의 없음'));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 8),
      itemBuilder: (context, i) {
        final it = items[i];
        return ListTile(
          dense: true,
          leading: Icon(
            it.status == '답변완료' ? Icons.check_circle : Icons.mark_chat_unread,
            color: it.status == '답변완료' ? Colors.green : Colors.orange,
          ),
          title: Text(it.title.isEmpty ? '(제목 없음)' : it.title),
          subtitle: Text('${DateFormat('yyyy.MM.dd HH:mm').format(it.createdAt)} · ${it.email}'),
          trailing: Text(it.status, style: const TextStyle(fontWeight: FontWeight.w600)),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.12),
          child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final int crossAxisCount;
  final List<Widget> children;
  const _ResponsiveGrid({required this.crossAxisCount, required this.children});

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.of(context).size.width;
    final double minCard = 360;
    final double targetWidth = (maxWidth - 32 - (crossAxisCount - 1) * 16) / crossAxisCount;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: children
          .map((w) => SizedBox(width: targetWidth.clamp(minCard, 9999), child: w))
          .toList(),
    );
  }
}