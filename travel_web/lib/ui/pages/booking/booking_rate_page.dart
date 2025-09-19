// lib/ui/pages/booking/booking_rate_page.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel_web/models/rate_overall.dart';
import 'package:travel_web/ui/widgets/rate_overall_list.dart';
import 'package:travel_web/utils/flight_meta.dart'; // kFlightTimes / kNonstopFromICN

class BookingRatePage extends StatefulWidget {
  const BookingRatePage({super.key});

  @override
  State<BookingRatePage> createState() => _BookingRatePageState();
}

class _BookingRatePageState extends State<BookingRatePage> {
  bool loading = false;
  Object? error;

  // 결과(항공편 전체 예매율, 내림차순 정렬)
  List<RateRowOverall> _rows = [];

  // ===== 검색 상태 =====
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(); // YYYY-MM-DD (표시용)
  String? _dateFilter;
  final _flightNoCtrl = TextEditingController(); // 접두사
  String? _flightNoPrefix;

  // IATA 후보
  List<String> get _iataOptions {
    final set = {...kFlightTimes.keys, ...kNonstopFromICN};
    final list = set.toList()..sort();
    return list;
  }

  // 좌석 분포 fallback (문서에 좌석_등급 값 없을 때 사용)
  static const _fallbackRatio = {
    '이코노미': 0.70,
    '프리미엄이코노미': 0.17,
    '비즈니스': 0.10,
    '퍼스트': 0.03,
  };

  // 보호 장치: 항공편 너무 많으면 일부만 계산 (필요시 늘려도 됨)
  static const int _MAX_FLIGHTS = 200; // 상한

  @override
  void initState() {
    super.initState();
    // ✅ 초기 진입 시 전체 조회
    _load();
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _dateCtrl.dispose();
    _flightNoCtrl.dispose();
    super.dispose();
  }

  int _asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

  Map<String, int> _seatCapacityMap(Map<String, dynamic> f) {
    final total = _asInt(f['총좌석']);
    final econ = _asInt(f['좌석_이코노미']);
    final prem = _asInt(f['좌석_프리미엄이코노미']);
    final biz = _asInt(f['좌석_비즈니스']);
    final first = _asInt(f['좌석_퍼스트']);

    if (econ + prem + biz + first > 0) {
      return {
        '이코노미': econ,
        '프리미엄이코노미': prem,
        '비즈니스': biz,
        '퍼스트': first,
      };
    }

    int e = (total * (_fallbackRatio['이코노미'] ?? 0)).round();
    int p = (total * (_fallbackRatio['프리미엄이코노미'] ?? 0)).round();
    int b = (total * (_fallbackRatio['비즈니스'] ?? 0)).round();
    int fcls = (total * (_fallbackRatio['퍼스트'] ?? 0)).round();
    final sum = e + p + b + fcls;
    final diff = total - sum; // 보정(반올림 오차)
    e += diff;

    return {
      '이코노미': max(0, e),
      '프리미엄이코노미': max(0, p),
      '비즈니스': max(0, b),
      '퍼스트': max(0, fcls),
    };
  }

  List<String>? _prefixRange(String? prefix) {
    if (prefix == null || prefix.isEmpty) return null;
    final p = prefix;
    final last = p.codeUnitAt(p.length - 1);
    final next = String.fromCharCode(last + 1);
    final end = p.substring(0, p.length - 1) + next;
    return [p, end];
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final fs = FirebaseFirestore.instance;

      Future<QuerySnapshot<Map<String, dynamic>>> fetchFlights(
        String collection, {
        String? origin,
        String? dest,
        String? date,
        String? prefix,
      }) async {
        Query<Map<String, dynamic>> q = fs.collection(collection);

        if (origin != null && origin.isNotEmpty) {
          q = q.where('출발지', isEqualTo: origin);
        }
        if (dest != null && dest.isNotEmpty) {
          q = q.where('목적지', isEqualTo: dest);
        }
        if (date != null && date.isNotEmpty) {
          q = q.where('운항일자', isEqualTo: date);
        }
        if (prefix != null && prefix.isNotEmpty) {
          final r = _prefixRange(prefix);
          if (r != null) {
            q = q.orderBy('운항편명').startAt([r[0]]).endBefore([r[1]]);
          }
        }
        q = q.limit(_MAX_FLIGHTS);
        return await q.get();
      }

      final origin = _originCtrl.text.trim().toUpperCase();
      final dest = _destCtrl.text.trim().toUpperCase();
      final prefix = _flightNoPrefix;

      final results = await Future.wait([
        fetchFlights(
          'airplane_start',
          origin: origin.isEmpty ? null : origin,
          dest: dest.isEmpty ? null : dest,
          date: _dateFilter,
          prefix: prefix,
        ),
        fetchFlights(
          'airplane_end',
          origin: origin.isEmpty ? null : origin,
          dest: dest.isEmpty ? null : dest,
          date: _dateFilter,
          prefix: prefix,
        ),
      ]);

      final flights = <String, Map<String, dynamic>>{};
      final collections = <String, String>{}; // flightId -> collection
      for (final d in results[0].docs) {
        flights[d.id] = d.data();
        collections[d.id] = 'airplane_start';
      }
      for (final d in results[1].docs) {
        flights[d.id] = d.data();
        collections[d.id] = 'airplane_end';
      }

      if (flights.isEmpty) {
        setState(() {
          _rows = [];
          loading = false;
        });
        return;
      }

      // booking 조회 (aid in whereIn), ❗️결제완료만
      final flightIds = flights.keys.toList();
      final chunkSize = 10;
      final List<Future<QuerySnapshot<Map<String, dynamic>>>> tasks = [];
      for (var i = 0; i < flightIds.length; i += chunkSize) {
        final ids = flightIds.sublist(i, min(i + chunkSize, flightIds.length));
        tasks.add(
          fs
              .collection('booking')
              .where('aid', whereIn: ids)
              .where('bState', isEqualTo: '결제완료')
              .get(),
        );
      }

      final bookingChunks = await Future.wait(tasks);

      // flightId -> 전체 예약 좌석 수
      final bookedByFlight = <String, int>{};
      for (final chunk in bookingChunks) {
        for (final b in chunk.docs) {
          final m = b.data();
          final fid = (m['aid'] ?? '').toString();
          final seats =
              (m['bSit'] as List?)?.cast<String>() ?? const <String>[];
          bookedByFlight[fid] = (bookedByFlight[fid] ?? 0) + seats.length;
        }
      }

      // RateRowOverall 구성 (내림차순 정렬)
      final rows = <RateRowOverall>[];
      for (final entry in flights.entries) {
        final fid = entry.key;
        final f = entry.value;
        final caps = _seatCapacityMap(f);
        final capacity = caps.values.fold<int>(0, (a, b) => a + b);
        final booked = bookedByFlight[fid] ?? 0;
        final rate = capacity > 0 ? booked / capacity : 0.0;

        rows.add(
          RateRowOverall(
            flightId: fid,
            collection: collections[fid] ?? 'airplane_start',
            flightNo:
                (f['운항편명'] ?? f['항공편번호'] ?? f['항공편'] ?? '').toString(),
            origin: (f['출발지'] ?? '').toString(),
            dest: (f['목적지'] ?? '').toString(),
            date: (f['운항일자'] ?? '').toString(),
            capacity: capacity,
            booked: booked,
            rate: rate,
          ),
        );
      }

      rows.sort((a, b) => b.rate.compareTo(a.rate));
      setState(() {
        _rows = rows;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  void _applyOrigin(String? code) {
    _originCtrl.text = (code ?? '').trim().toUpperCase();
    _load();
  }

  void _applyDest(String? code) {
    _destCtrl.text = (code ?? '').trim().toUpperCase();
    _load();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final s =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _dateFilter = s;
      _dateCtrl.text = s;
      _load();
    }
  }

  void _clearDate() {
    _dateFilter = null;
    _dateCtrl.clear();
    _load();
  }

  void _applyFlightNoPrefix() {
    final s = _flightNoCtrl.text.trim().toUpperCase();
    _flightNoPrefix = s.isEmpty ? null : s;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예매율'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // ===== 검색 패널: 본문 상단 =====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  children: [
                    // 1행: 출발지/목적지
                    Row(
                      children: [
                        const SizedBox(
                          width: 56,
                          child: Text('출발지',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue v) {
                              final q = v.text.trim().toUpperCase();
                              if (q.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return _iataOptions.where((x) => x.startsWith(q));
                            },
                            fieldViewBuilder:
                                (context, textController, focusNode, _) {
                              if (textController.text.isEmpty &&
                                  _originCtrl.text.isNotEmpty) {
                                textController.text = _originCtrl.text;
                                textController.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset:
                                            textController.text.length));
                              }
                              return TextField(
                                controller: textController,
                                focusNode: focusNode,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: '예: ICN, NRT',
                                  prefixIcon: Icon(Icons.flight_takeoff),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (v) => _applyOrigin(v),
                              );
                            },
                            onSelected: (s) => _applyOrigin(s),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 56,
                          child: Text('목적지',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue v) {
                              final q = v.text.trim().toUpperCase();
                              if (q.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return _iataOptions.where((x) => x.startsWith(q));
                            },
                            fieldViewBuilder:
                                (context, textController, focusNode, _) {
                              if (textController.text.isEmpty &&
                                  _destCtrl.text.isNotEmpty) {
                                textController.text = _destCtrl.text;
                                textController.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset:
                                            textController.text.length));
                              }
                              return TextField(
                                controller: textController,
                                focusNode: focusNode,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: '예: ICN, NRT',
                                  prefixIcon: Icon(Icons.flight_land),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (v) => _applyDest(v),
                              );
                            },
                            onSelected: (s) => _applyDest(s),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 2행: 날짜 / 편명 접두사 / 검색 버튼
                    Row(
                      children: [
                        const SizedBox(
                          width: 56,
                          child: Text('날짜',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _dateCtrl,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'YYYY-MM-DD',
                              prefixIcon: const Icon(Icons.event),
                              suffixIcon: (_dateFilter == null)
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearDate,
                                    ),
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 56,
                          child: Text('편명',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _flightNoCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: '예: KE (접두사)',
                              prefixIcon: const Icon(Icons.tag),
                              suffixIcon: (_flightNoCtrl.text.isEmpty)
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _flightNoCtrl.clear();
                                        _flightNoPrefix = null;
                                        _load();
                                      },
                                    ),
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _applyFlightNoPrefix(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _applyFlightNoPrefix,
                          icon: const Icon(Icons.search),
                          label: const Text('검색'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== 결과(상위만, 내림차순 전체) =====
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : (error != null
                    ? Center(child: Text('오류: $error'))
                    : RateOverallList(rows: _rows)),
          ),
        ],
      ),
    );
  }
}