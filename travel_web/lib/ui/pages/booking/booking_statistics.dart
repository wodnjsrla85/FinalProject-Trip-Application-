// booking_stats_page.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// 예매 통계 페이지 (연동판)
/// - 탭: 개요(실데이터) / 노선별(실데이터) / 좌석등급(시간대 수요)
/// - 모든 쿼리: booking.bDate 단일 필드 범위 + orderBy('bDate') (복합 인덱스 불필요)
/// - 노선/시간대 분석: what != '패키지' 만 대상으로 aid → airplane_start/end 메타 조인(출발시간/총좌석/노선정보)
/// - 좌석 수: booking.bSit.length
/// - 좌석등급: bSit의 첫 글자(F/B/P/E)

class BookingStatsPage extends StatefulWidget {
  const BookingStatsPage({super.key});

  @override
  State<BookingStatsPage> createState() => _BookingStatsPageState();
}

class _BookingStatsPageState extends State<BookingStatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = false;
  Object? _error;

  // Filters
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String? _origin = "ICN";
  String? _dest;
  String? _cabin; // F/B/P/E 필터(전체면 null)

  // ── 개요 탭 데이터 ─────────────────────────────────
  int _kpiTotalSeatsThisMonth = 0; // 이달 결제완료 좌석 수(패키지 포함)
  int _kpiTotalRevenueThisMonth = 0; // 이달 결제완료 총액(패키지 포함)
  double _kpiCancelRateThisMonth = 0.0; // 이달 취소율(간이)
  List<_MonthPoint> _monthly = [];       // 올해 월별 결제완료 좌석 수
  List<_RouteStat> _topRoutes = [];      // 이달 노선별 TOP5(좌석수, 패키지 제외)
  List<_FareBin> _fareBins = [];         // 이달 좌석당 운임 히스토그램

  // ── 노선별 탭 데이터 ───────────────────────────────
  Map<String, List<int>> _routeMonthlySeats = {}; // route -> [12]
  List<_RouteLoad> _routeLoadsThisMonth = [];
  List<_WeekdayPoint> _weekdayThisMonth = [];

  // ── 좌석등급(시간대 수요) 탭 데이터 ─────────────────
  // 등급별 24시간 버킷: 'F','B','P','E' -> [0..23]
  Map<String, List<int>> _classHourly = {
    'F': List.filled(24, 0),
    'B': List.filled(24, 0),
    'P': List.filled(24, 0),
    'E': List.filled(24, 0),
  };

  // ── 툴팁/포맷 ─────────────────────────────────────
  final _wonFmt = NumberFormat.decimalPattern('ko_KR');
  String _wonInt(int v) => _wonFmt.format(v);
  late TooltipBehavior _tooltip;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tooltip = TooltipBehavior(enable: true, canShowMarker: true);
    _loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── 날짜/파서 유틸 ─────────────────────────────────
  String _fmtYmd(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
  (String start, String end) _monthRangeStr(int y, int m) {
    final s = DateTime(y, m, 1);
    final e = DateTime(y, m + 1, 1);
    return (_fmtYmd(s), _fmtYmd(e));
  }
  (String start, String end) _yearRangeStr(int y) {
    final s = DateTime(y, 1, 1);
    final e = DateTime(y + 1, 1, 1);
    return (_fmtYmd(s), _fmtYmd(e));
  }
  int _asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
  String _safeStr(dynamic v) => (v ?? '').toString();

  int _seatCount(dynamic bSit) => (bSit is List) ? bSit.length : 0;

  bool _bookingMatchesCabin(dynamic bSit, String wanted) {
    if (wanted.isEmpty) return true;
    if (bSit is! List) return false;
    return bSit.any((s) {
      final t = _safeStr(s);
      return t.isNotEmpty && t[0].toUpperCase() == wanted.toUpperCase();
    });
  }

  String _seatClassPrefix(String s) {
    if (s.isEmpty) return '';
    final c = s[0].toUpperCase();
    return (c == 'F' || c == 'B' || c == 'P' || c == 'E') ? c : '';
  }

  int? _hourFromTime(String? hhmm) {
    if (hhmm == null || hhmm.length < 2) return null;
    final hh = int.tryParse(hhmm.substring(0, 2));
    if (hh == null || hh < 0 || hh > 23) return null;
    return hh;
    // 분은 버킷에 영향 없음
  }

  // airplane_start/end 에서 여러 id 조회
  Future<Map<String, Map<String, dynamic>>> _fetchAirMeta(List<String> ids) async {
    final Map<String, Map<String, dynamic>> out = {};
    if (ids.isEmpty) return out;

    Future<void> fetchChunk(String col, List<String> chunkIds) async {
      final qs = await FirebaseFirestore.instance
          .collection(col)
          .where(FieldPath.documentId, whereIn: chunkIds)
          .get();
      for (final d in qs.docs) {
        out[d.id] = d.data();
      }
    }

    const step = 10; // whereIn 제한
    for (var i = 0; i < ids.length; i += step) {
      final part = ids.sublist(i, min(i + step, ids.length));
      await fetchChunk('airplane_start', part);
      await fetchChunk('airplane_end', part);
    }
    return out;
  }

  // ── 데이터 로드 ────────────────────────────────────
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadOverview(),
        _loadRoutesTab(),
        _loadCabinSeatClassTab(), // ← 변경된 탭 로딩
      ]);

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  // 개요: KPI + 연간 월별 + 이달 TOP5 + 운임분포
  Future<void> _loadOverview() async {
    final (mStart, mEnd) = _monthRangeStr(_year, _month);
    final qsMonth = await FirebaseFirestore.instance
        .collection('booking')
        .where('bDate', isGreaterThanOrEqualTo: mStart)
        .where('bDate', isLessThan: mEnd)
        .orderBy('bDate')
        .get();

    int monthSeats = 0;
    int monthRevenue = 0;
    int monthCancelledSeats = 0;

    final Map<String, int> seatsByAidThisMonth = {};
    final List<double> perSeatFares = [];
    final Set<String> aidsNeedMeta = {};

    for (final d in qsMonth.docs) {
      final m = d.data();
      final state = _safeStr(m['bState']);
      final seats = _seatCount(m['bSit']);
      final what = _safeStr(m['what']);
      final aid = _safeStr(m['aid']);

      // 좌석등급 필터(선택시)
      if ((_cabin ?? '').isNotEmpty && !_bookingMatchesCabin(m['bSit'], _cabin!)) {
        continue;
      }

      if (state == '결제완료') {
        monthSeats += seats;
        monthRevenue += _asInt(m['aPrice']);

        if (seats > 0) {
          perSeatFares.add(_asInt(m['aPrice']) / seats);
        }

        if (what != '패키지' && aid.isNotEmpty) {
          aidsNeedMeta.add(aid);
          seatsByAidThisMonth[aid] = (seatsByAidThisMonth[aid] ?? 0) + seats;
        }
      } else if (state.contains('취소')) {
        monthCancelledSeats += max(1, seats);
      }
    }

    Map<String, Map<String, dynamic>> meta = {};
    if (aidsNeedMeta.isNotEmpty) {
      meta = await _fetchAirMeta(aidsNeedMeta.toList());
    }

    Map<String, int> seatsByAidFiltered = seatsByAidThisMonth;
    if ((_origin ?? '').isNotEmpty || (_dest ?? '').isNotEmpty) {
      final org = _origin?.isNotEmpty == true ? _origin : null;
      final dst = _dest?.isNotEmpty == true ? _dest : null;
      final filtered = <String, int>{};
      seatsByAidThisMonth.forEach((aid, s) {
        final mm = meta[aid];
        final o = _safeStr(mm?['출발지']);
        final t = _safeStr(mm?['목적지']);
        final okO = org == null || o == org;
        final okD = dst == null || t == dst;
        if (okO && okD) filtered[aid] = s;
      });
      seatsByAidFiltered = filtered;
    }

    final topRoutes = <_RouteStat>[];
    seatsByAidFiltered.forEach((aid, seats) {
      final mm = meta[aid];
      final o = _safeStr(mm?['출발지']);
      final t = _safeStr(mm?['목적지']);
      final label = '${o.isEmpty ? '미상' : o} → ${t.isEmpty ? '미상' : t}';
      topRoutes.add(_RouteStat(label, seats));
    });
    topRoutes.sort((a, b) => b.value.compareTo(a.value));

    final totalForCancel = monthSeats + monthCancelledSeats;
    final cancelRate = totalForCancel == 0
        ? 0.0
        : (monthCancelledSeats / totalForCancel) * 100.0;

    final (yStart, yEnd) = _yearRangeStr(_year);
    final qsYear = await FirebaseFirestore.instance
        .collection('booking')
        .where('bDate', isGreaterThanOrEqualTo: yStart)
        .where('bDate', isLessThan: yEnd)
        .orderBy('bDate')
        .get();

    final monthly = List.generate(12, (i) => _MonthPoint(i + 1, '${i + 1}월', 0));
    for (final d in qsYear.docs) {
      final m = d.data();
      if (_safeStr(m['bState']) != '결제완료') continue;
      if ((_cabin ?? '').isNotEmpty && !_bookingMatchesCabin(m['bSit'], _cabin!)) {
        continue;
      }
      final s = _safeStr(m['bDate']);
      if (s.length < 7) continue;
      final mm = int.tryParse(s.substring(5, 7));
      if (mm != null && mm >= 1 && mm <= 12) {
        monthly[mm - 1].count += _seatCount(m['bSit']);
      }
    }

    _kpiTotalSeatsThisMonth = monthSeats;
    _kpiTotalRevenueThisMonth = monthRevenue;
    _kpiCancelRateThisMonth = cancelRate;
    _topRoutes = topRoutes.take(5).toList();
    _monthly = monthly;
    _fareBins = _buildFareHistogram(perSeatFares);
  }

  // 노선별 탭 로딩(기존과 동일)
  Future<void> _loadRoutesTab() async {
    final (yStart, yEnd) = _yearRangeStr(_year);
    final qsYear = await FirebaseFirestore.instance
        .collection('booking')
        .where('bDate', isGreaterThanOrEqualTo: yStart)
        .where('bDate', isLessThan: yEnd)
        .orderBy('bDate')
        .get();

    final Map<String, List<int>> seatsByAidMonthly = {};
    final (mStart, mEnd) = _monthRangeStr(_year, _month);
    final Map<String, int> monthAidBookedSeats = {};
    final weekdayCounts = List<int>.filled(7, 0);
    final Set<String> aidsNeedMeta = {};

    for (final d in qsYear.docs) {
      final m = d.data();
      final state = _safeStr(m['bState']);
      final bdate = _safeStr(m['bDate']);
      final what = _safeStr(m['what']);
      final aid = _safeStr(m['aid']);
      if (what == '패키지' || aid.isEmpty) continue;

      if ((_cabin ?? '').isNotEmpty && !_bookingMatchesCabin(m['bSit'], _cabin!)) {
        continue;
      }

      aidsNeedMeta.add(aid);

      if (state == '결제완료') {
        final seats = _seatCount(m['bSit']);
        if (bdate.length >= 7) {
          final mm = int.tryParse(bdate.substring(5, 7));
          if (mm != null && mm >= 1 && mm <= 12) {
            final arr = seatsByAidMonthly.putIfAbsent(aid, () => List<int>.filled(12, 0));
            arr[mm - 1] += seats;
          }
        }
        if (bdate.compareTo(mStart) >= 0 && bdate.compareTo(mEnd) < 0) {
          monthAidBookedSeats[aid] = (monthAidBookedSeats[aid] ?? 0) + seats;
          try {
            final wd = DateTime.parse(bdate).weekday;
            weekdayCounts[wd - 1] += seats;
          } catch (_) {}
        }
      }
    }

    final meta = await _fetchAirMeta(aidsNeedMeta.toList());
    bool needRouteFilter = (_origin ?? '').isNotEmpty || (_dest ?? '').isNotEmpty;
    String? org = _origin?.isNotEmpty == true ? _origin : null;
    String? dst = _dest?.isNotEmpty == true ? _dest : null;

    final Map<String, List<int>> routeMonthly = {};
    seatsByAidMonthly.forEach((aid, seats12) {
      final m = meta[aid];
      final o = _safeStr(m?['출발지']);
      final t = _safeStr(m?['목적지']);
      if (needRouteFilter) {
        final okO = org == null || o == org;
        final okD = dst == null || t == dst;
        if (!(okO && okD)) return;
      }
      final route = '${o.isEmpty ? "미상" : o} → ${t.isEmpty ? "미상" : t}';
      final arr = routeMonthly.putIfAbsent(route, () => List<int>.filled(12, 0));
      for (int i = 0; i < 12; i++) {
        arr[i] += seats12[i];
      }
    });

    final routesRanked = routeMonthly.entries.toList()
      ..sort((a, b) =>
          b.value.fold<int>(0, (s, v) => s + v).compareTo(a.value.fold<int>(0, (s, v) => s + v)));
    final top5Routes = routesRanked.take(5).toList();
    final Map<String, List<int>> finalRouteMonthly = {
      for (final e in top5Routes) e.key: e.value,
    };

    final Map<String, int> routeBooked = {};
    final Map<String, int> routeCapacity = {};
    final Set<String> routeAidCounted = {};

    monthAidBookedSeats.forEach((aid, booked) {
      final m = meta[aid];
      final o = _safeStr(m?['출발지']);
      final t = _safeStr(m?['목적지']);
      if (needRouteFilter) {
        final okO = org == null || o == org;
        final okD = dst == null || t == dst;
        if (!(okO && okD)) return;
      }
      final route = '${o.isEmpty ? "미상" : o} → ${t.isEmpty ? "미상" : t}';
      routeBooked[route] = (routeBooked[route] ?? 0) + booked;

      if (!routeAidCounted.contains(aid)) {
        final cap = _asInt(m?['총좌석']);
        routeCapacity[route] = (routeCapacity[route] ?? 0) + cap;
        routeAidCounted.add(aid);
      }
    });

    final routeLoads = <_RouteLoad>[];
    routeBooked.forEach((route, booked) {
      final cap = max(1, routeCapacity[route] ?? 0);
      final lf = booked / cap;
      routeLoads.add(_RouteLoad(route: route, booked: booked, capacity: cap, loadFactor: lf));
    });
    routeLoads.sort((a, b) => b.loadFactor.compareTo(a.loadFactor));

    final weekdayPts = <_WeekdayPoint>[];
    const labels = ['월','화','수','목','금','토','일'];
    for (int i = 0; i < 7; i++) {
      weekdayPts.add(_WeekdayPoint(labels[i], weekdayCounts[i]));
    }

    _routeMonthlySeats = finalRouteMonthly;
    _routeLoadsThisMonth = routeLoads;
    _weekdayThisMonth = weekdayPts;
  }

  // 좌석등급 탭(시간대 수요): 이번 달, 항공기만, 결제완료
  Future<void> _loadCabinSeatClassTab() async {
    // 초기화
    final classHourly = {
      'F': List<int>.filled(24, 0),
      'B': List<int>.filled(24, 0),
      'P': List<int>.filled(24, 0),
      'E': List<int>.filled(24, 0),
    };

    final (mStart, mEnd) = _monthRangeStr(_year, _month);
    final qs = await FirebaseFirestore.instance
        .collection('booking')
        .where('bDate', isGreaterThanOrEqualTo: mStart)
        .where('bDate', isLessThan: mEnd)
        .orderBy('bDate')
        .get();

    // 항공기만 메타 필요
    final Map<String, List<List<dynamic>>> aidToSeatsList = {}; 
    // aid -> List<List<dynamic>> (해당 aid의 각 예약의 bSit 배열들)
    for (final d in qs.docs) {
      final m = d.data();
      if (_safeStr(m['bState']) != '결제완료') continue;
      if (_safeStr(m['what']) == '패키지') continue;

      // 좌석등급 필터가 있으면 해당 예약이 적어도 1좌석 매칭될 때만 포함
      if ((_cabin ?? '').isNotEmpty && !_bookingMatchesCabin(m['bSit'], _cabin!)) {
        continue;
      }

      final aid = _safeStr(m['aid']);
      if (aid.isEmpty) continue;

      final seats = (m['bSit'] is List) ? (m['bSit'] as List) : const [];
      if (seats.isEmpty) continue;

      aidToSeatsList.putIfAbsent(aid, () => <List<dynamic>>[]).add(seats);
    }

    if (aidToSeatsList.isEmpty) {
      _classHourly = classHourly;
      return;
    }

    // 출발시간 조회
    final meta = await _fetchAirMeta(aidToSeatsList.keys.toList());

    // 시간 버킷에 좌석등급별로 합산
    aidToSeatsList.forEach((aid, allSeatsLists) {
      final m = meta[aid];
      final dep = _safeStr(m?['출발시간']); // "HH:mm"
      final hour = _hourFromTime(dep);
      if (hour == null) return;

      for (final seats in allSeatsLists) {
        for (final s in seats) {
          final prefix = _seatClassPrefix(_safeStr(s));
          if (classHourly.containsKey(prefix)) {
            classHourly[prefix]![hour] += 1;
          }
        }
      }
    });

    _classHourly = classHourly;
  }

  // 운임 히스토그램
  List<_FareBin> _buildFareHistogram(List<double> fares) {
    if (fares.isEmpty) return [];
    final n = fares.length;
    final minV = fares.reduce(min);
    final maxV = fares.reduce(max);
    if (minV == maxV) {
      final label = '₩${_wonInt(minV.round())}';
      return [ _FareBin(label, n) ];
    }
    int bins = n < 40 ? 5 : 10;
    final width = (maxV - minV) / bins;
    final counts = List<int>.filled(bins, 0);
    for (final v in fares) {
      int idx = ((v - minV) / width).floor();
      if (idx >= bins) idx = bins - 1;
      counts[idx] += 1;
    }
    final labels = List<String>.generate(bins, (i) {
      final a = (minV + i * width).round();
      final b = (minV + (i + 1) * width).round();
      return '₩${_wonInt(a)}~${_wonInt(b)}';
    });
    return List.generate(bins, (i) => _FareBin(labels[i], counts[i]));
  }

  // ── UI ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_year}.${_month.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('예매 통계'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.dashboard_outlined),
            label: const Text('대시보드로'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            year: _year,
            month: _month,
            origin: _origin,
            dest: _dest,
            cabin: _cabin,
            onApply: (y, m, o, d, c) {
              setState(() {
                _year = y;
                _month = m;
                _origin = o;
                _dest = d;
                _cabin = c;
              });
              _loadAll();
            },
            onReset: () {
              setState(() {
                _year = DateTime.now().year;
                _month = DateTime.now().month;
                _origin = "ICN";
                _dest = null;
                _cabin = null;
              });
              _loadAll();
            },
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: _error != null
                ? Center(child: Text('오류: $_error'))
                : Column(
                    children: [
                      TabBar(
                        controller: _tab,
                        isScrollable: true,
                        tabs: const [
                          Tab(text: '개요'),
                          Tab(text: '노선별'),
                          Tab(text: '좌석등급(시간대)'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            _OverviewTab(
                              monthLabel: monthLabel,
                              kpiTotalSeats: _kpiTotalSeatsThisMonth,
                              kpiTotalRevenue: _kpiTotalRevenueThisMonth,
                              kpiCancelRate: _kpiCancelRateThisMonth,
                              monthly: _monthly,
                              topRoutes: _topRoutes,
                              fareBins: _fareBins,
                            ),
                            _RoutesTab(
                              routeMonthlySeats: _routeMonthlySeats,
                              routeLoadsThisMonth: _routeLoadsThisMonth,
                              weekdayThisMonth: _weekdayThisMonth,
                              tooltip: _tooltip,
                            ),
                            _CabinSeatClassTab(
                              classHourly: _classHourly,
                              tooltip: _tooltip,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// --------------------------- Filters -----------------------------

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.year,
    required this.month,
    required this.origin,
    required this.dest,
    required this.cabin,
    required this.onApply,
    required this.onReset,
  });

  final int year;
  final int month;
  final String? origin;
  final String? dest;
  final String? cabin;

  final void Function(
    int year,
    int month,
    String? origin,
    String? dest,
    String? cabin,
  ) onApply;

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final years = [2023, 2024, 2025, 2026];
    final months = List.generate(12, (i) => i + 1);
    final origins = [null, "ICN", "GMP", "PUS", "CJU"];
    final dests = [null, "NRT", "KIX", "TPE", "LAX", "CJU", "FUK", "ICN"];
    final cabins = [null, "F", "B", "P", "E"]; // F/B/P/E

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ChipField<int>(
            label: '연도',
            value: year,
            items: years,
            display: (v) => v.toString(),
            onChanged: (_) {},
          ),
          _ChipField<int>(
            label: '월',
            value: month,
            items: months,
            display: (v) => v.toString().padLeft(2, '0'),
            onChanged: (_) {},
          ),
          _DropField<String?>(
            label: '출발지',
            value: origin,
            items: origins,
            display: (v) => v ?? '전체',
          ),
          _DropField<String?>(
            label: '도착지',
            value: dest,
            items: dests,
            display: (v) => v ?? '전체',
          ),
          _DropField<String?>(
            label: '좌석등급(필터)',
            value: cabin,
            items: cabins,
            display: (v) {
              if (v == null) return '전체';
              switch (v) {
                case 'F': return '퍼스트(F)';
                case 'B': return '비즈니스(B)';
                case 'P': return '프리미엄이코노미(P)';
                case 'E': return '이코노미(E)';
              }
              return v;
            },
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => onApply(year, month, origin, dest, cabin),
            icon: const Icon(Icons.playlist_add_check),
            label: const Text('적용'),
          ),
          TextButton(onPressed: onReset, child: const Text('초기화')),
        ],
      ),
    );
  }
}

/// --------------------------- 개요 탭 -----------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.monthLabel,
    required this.kpiTotalSeats,
    required this.kpiTotalRevenue,
    required this.kpiCancelRate,
    required this.monthly,
    required this.topRoutes,
    required this.fareBins,
  });

  final String monthLabel;
  final int kpiTotalSeats;
  final int kpiTotalRevenue;
  final double kpiCancelRate;
  final List<_MonthPoint> monthly;
  final List<_RouteStat> topRoutes;
  final List<_FareBin> fareBins;

  String _fmtInt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1200;
    final isMedium = MediaQuery.of(context).size.width >= 900 &&
        MediaQuery.of(context).size.width < 1200;
    final gridCount = isWide ? 5 : (isMedium ? 3 : 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: gridCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _KpiCard(title: '총 예매 좌석수 ($monthLabel)', value: '${_fmtInt(kpiTotalSeats)}석', icon: Icons.event_seat),
              _KpiCard(title: '총 매출(KRW)', value: '₩ ${_fmtInt(kpiTotalRevenue)}', icon: Icons.payments),
              _KpiCard(title: '취소율', value: '${kpiCancelRate.toStringAsFixed(1)}%', icon: Icons.cancel_schedule_send),
            ],
          ),
          const SizedBox(height: 16),

          _RowWrap(
            isWide: isWide,
            left: Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: _wireDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('연간 월별 예매 좌석수(결제완료)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SfCartesianChart(
                        primaryXAxis: const CategoryAxis(),
                        primaryYAxis: const NumericAxis(decimalPlaces: 0),
                        series: <CartesianSeries<_MonthPoint, String>>[
                          ColumnSeries<_MonthPoint, String>(
                            name: '좌석수',
                            dataSource: monthly,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.count,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            right: Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: _wireDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('노선별 예약 TOP5 (이달 · 패키지 제외, 좌석수)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: topRoutes.length,
                        separatorBuilder: (_, __) => const Divider(height: 8),
                        itemBuilder: (context, i) {
                          final r = topRoutes[i];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey.shade300,
                              child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            title: Text(r.label),
                            trailing: Text('${_fmtInt(r.value)}석'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              height: 280,
              padding: const EdgeInsets.all(16),
              decoration: _wireDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('좌석당 운임 분포(이달 · 결제완료)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(labelRotation: -30),
                      primaryYAxis: const NumericAxis(decimalPlaces: 0),
                      series: <CartesianSeries<_FareBin, String>>[
                        ColumnSeries<_FareBin, String>(
                          name: '건수',
                          dataSource: fareBins,
                          xValueMapper: (b, _) => b.label,
                          yValueMapper: (b, _) => b.count,
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('계산: aPrice / 좌석수', style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------------- 노선별 탭(동일) -----------------------------

class _RoutesTab extends StatelessWidget {
  const _RoutesTab({
    required this.routeMonthlySeats,
    required this.routeLoadsThisMonth,
    required this.weekdayThisMonth,
    required this.tooltip,
  });

  final Map<String, List<int>> routeMonthlySeats; // route -> [12]
  final List<_RouteLoad> routeLoadsThisMonth;
  final List<_WeekdayPoint> weekdayThisMonth;
  final TooltipBehavior tooltip;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1200;

    final series = <LineSeries<_MonthPoint, String>>[];
    final months = List.generate(12, (i) => _MonthPoint(i + 1, '${i + 1}월', 0));
    routeMonthlySeats.forEach((route, arr) {
      final ds = List<_MonthPoint>.generate(12, (i) => _MonthPoint(i + 1, '${i + 1}월', arr[i]));
      series.add(
        LineSeries<_MonthPoint, String>(
          name: route,
          dataSource: ds,
          xValueMapper: (d, _) => d.label,
          yValueMapper: (d, _) => d.count,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          _RowWrap(
            isWide: isWide,
            left: Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Container(
                height: 320,
                padding: const EdgeInsets.all(16),
                decoration: _wireDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('노선별 월간 좌석수(올해, TOP5)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SfCartesianChart(
                        tooltipBehavior: tooltip,
                        legend: const Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                        primaryXAxis: const CategoryAxis(),
                        primaryYAxis: const NumericAxis(decimalPlaces: 0),
                        series: series.isEmpty
                            ? <CartesianSeries<_MonthPoint, String>>[
                                LineSeries<_MonthPoint, String>(
                                  name: '데이터 없음',
                                  dataSource: months,
                                  xValueMapper: (d, _) => d.label,
                                  yValueMapper: (d, _) => 0,
                                ),
                              ]
                            : series,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            right: Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Container(
                height: 320,
                padding: const EdgeInsets.all(16),
                decoration: _wireDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('노선별 탑재율(이번 달)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SfCartesianChart(
                        primaryXAxis: const CategoryAxis(),
                        primaryYAxis: NumericAxis(
                          minimum: 0, maximum: 1, interval: 0.2,
                          numberFormat: NumberFormat.percentPattern(),
                        ),
                        series: <CartesianSeries<_RouteLoad, String>>[
                          ColumnSeries<_RouteLoad, String>(
                            name: '탑재율',
                            dataSource: routeLoadsThisMonth,
                            xValueMapper: (r, _) => r.route,
                            yValueMapper: (r, _) => r.loadFactor,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              height: 320,
              padding: const EdgeInsets.all(16),
              decoration: _wireDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('요일별 좌석 예약 분포(이번 달)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      primaryYAxis: const NumericAxis(decimalPlaces: 0),
                      series: <CartesianSeries<_WeekdayPoint, String>>[
                        ColumnSeries<_WeekdayPoint, String>(
                          name: '좌석수',
                          dataSource: weekdayThisMonth,
                          xValueMapper: (w, _) => w.label,
                          yValueMapper: (w, _) => w.count,
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------------- 좌석등급(시간대) 탭 -----------------------------

class _CabinSeatClassTab extends StatelessWidget {
  const _CabinSeatClassTab({
    required this.classHourly,
    required this.tooltip,
  });

  final Map<String, List<int>> classHourly; // 'F'/'B'/'P'/'E' -> 24 길이
  final TooltipBehavior tooltip;

  List<_HourPoint> _seriesFrom(Map<String, List<int>> data, String cls) {
    final arr = data[cls] ?? List<int>.filled(24, 0);
    return List<_HourPoint>.generate(24, (h) => _HourPoint(h, '$h시', arr[h]));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1200;

    final fSeries = _seriesFrom(classHourly, 'F');
    final bSeries = _seriesFrom(classHourly, 'B');
    final pSeries = _seriesFrom(classHourly, 'P');
    final eSeries = _seriesFrom(classHourly, 'E');

    // 스택 컬럼(시간대 × 등급)
    final stacked = [
      StackedColumnSeries<_HourPoint, String>(
        name: '퍼스트(F)',
        dataSource: fSeries,
        xValueMapper: (p, _) => p.label,
        yValueMapper: (p, _) => p.value,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ),
      StackedColumnSeries<_HourPoint, String>(
        name: '비즈니스(B)',
        dataSource: bSeries,
        xValueMapper: (p, _) => p.label,
        yValueMapper: (p, _) => p.value,
      ),
      StackedColumnSeries<_HourPoint, String>(
        name: '프리미엄이코노미(P)',
        dataSource: pSeries,
        xValueMapper: (p, _) => p.label,
        yValueMapper: (p, _) => p.value,
      ),
      StackedColumnSeries<_HourPoint, String>(
        name: '이코노미(E)',
        dataSource: eSeries,
        xValueMapper: (p, _) => p.label,
        yValueMapper: (p, _) => p.value,
      ),
    ];

    Widget _smallMultiple(String title, List<_HourPoint> ds) {
      return Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _wireDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0), interval: 2),
                  primaryYAxis: const NumericAxis(decimalPlaces: 0),
                  series: <CartesianSeries<_HourPoint, String>>[
                    ColumnSeries<_HourPoint, String>(
                      name: title,
                      dataSource: ds,
                      xValueMapper: (p, _) => p.label,
                      yValueMapper: (p, _) => p.value,
                      dataLabelSettings: const DataLabelSettings(isVisible: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          // 1) 전체 스택
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              height: 360,
              padding: const EdgeInsets.all(16),
              decoration: _wireDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('시간대별 좌석등급 수요(이달, 항공편)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SfCartesianChart(
                      tooltipBehavior: tooltip,
                      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                      primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                      primaryYAxis: const NumericAxis(decimalPlaces: 0),
                      series: stacked,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 2) 스몰멀티플 4개
          GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _smallMultiple('퍼스트(F)', fSeries),
              _smallMultiple('비즈니스(B)', bSeries),
              _smallMultiple('프리미엄이코노미(P)', pSeries),
              _smallMultiple('이코노미(E)', eSeries),
            ],
          ),
        ],
      ),
    );
  }
}

/// --------------------------- 재사용/모델 -----------------------------

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _wireDecoration(),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WireChartBox extends StatelessWidget {
  const _WireChartBox({
    required this.title,
    required this.hint,
    this.height = 240,
  });

  final String title;
  final String hint;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: _wireDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(child: _WireCanvas(hint: hint)),
          ],
        ),
      ),
    );
  }
}

class _WireCanvas extends StatelessWidget {
  const _WireCanvas({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return Stack(
        children: [
          CustomPaint(
            size: Size(c.maxWidth, c.maxHeight),
            painter: _DashedPainter(),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              hint,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black38),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    });
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(12),
    );

    const dashW = 6.0, dashGap = 6.0;
    final path = Path()..addRRect(rect);
    for (final m in path.computeMetrics()) {
      double dist = 0.0;
      while (dist < m.length) {
        final next = dist + dashW;
        canvas.drawPath(m.extractPath(dist, next), paint);
        dist = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _wireDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.black26, width: 1.2),
  );
}

class _RowWrap extends StatelessWidget {
  const _RowWrap({
    required this.isWide,
    required this.left,
    required this.right,
  });

  final bool isWide;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      );
    }
    return Column(
      children: [
        left,
        const SizedBox(height: 12),
        right,
      ],
    );
  }
}

// ── 모델 ─────────────────────
class _MonthPoint {
  final int month;    // 1~12
  final String label; // "1월"
  int count;
  _MonthPoint(this.month, this.label, this.count);
}

class _RouteStat {
  final String label; // "ICN → NRT"
  final int value;    // 좌석 수
  _RouteStat(this.label, this.value);
}

class _WeekdayPoint {
  final String label; // 월..일
  final int count;
  _WeekdayPoint(this.label, this.count);
}

class _RouteLoad {
  final String route;
  final int booked;
  final int capacity;
  final double loadFactor;
  _RouteLoad({
    required this.route,
    required this.booked,
    required this.capacity,
    required this.loadFactor,
  });
}

class _FareBin {
  final String label;
  final int count;
  _FareBin(this.label, this.count);
}

class _HourPoint {
  final int hour;   // 0~23
  final String label; // "0시" ..
  final int value;
  _HourPoint(this.hour, this.label, this.value);
}

/// 선택/드롭다운 공용 ─────────────────────────

class _ChipField<T> extends StatelessWidget {
  const _ChipField({
    required this.label,
    required this.value,
    required this.items,
    required this.display,
    this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        isDense: true,
      ),
      child: Wrap(
        spacing: 8,
        children: items.map((e) {
          final selected = e == value;
          return ChoiceChip(
            label: Text(display(e)),
            selected: selected,
            onSelected: (_) => onChanged?.call(e),
          );
        }).toList(),
      ),
    );
  }
}

class _DropField<T> extends StatefulWidget {
  const _DropField({
    required this.label,
    required this.value,
    required this.items,
    required this.display,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) display;

  @override
  State<_DropField<T>> createState() => _DropFieldState<T>();
}

class _DropFieldState<T> extends State<_DropField<T>> {
  late T _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
  }

  @override
  void didUpdateWidget(covariant _DropField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _current = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        value: _current,
        items: widget.items
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(widget.display(e)),
                ))
            .toList(),
        onChanged: (v) => setState(() {
          if (v != null) _current = v;
        }),
        decoration: InputDecoration(
          labelText: widget.label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}