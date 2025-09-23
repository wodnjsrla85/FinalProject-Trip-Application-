// lib/ui/pages/booking/booking_rate_detail_page.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingRateDetailPage extends StatefulWidget {
  final String flightId;
  final String collection; // 'airplane_start' | 'airplane_end'
  const BookingRateDetailPage({
    super.key,
    required this.flightId,
    required this.collection,
  });

  @override
  State<BookingRateDetailPage> createState() => _BookingRateDetailPageState();
}

class _BookingRateDetailPageState extends State<BookingRateDetailPage> {
  bool loading = true;
  Object? error;

  Map<String, dynamic>? _flight;
  late Map<String, int> _cap;     // 등급별 좌석 수용
  late Map<String, int> _booked;  // 등급별 예매 좌석 수

  // 수익(결제완료 기준)
  int _revenueTotal = 0;
  final Map<String, int> _revenueByCls = {
    '이코노미': 0,
    '프리미엄이코노미': 0,
    '비즈니스': 0,
    '퍼스트': 0,
  };

  // 등급별 표시용: "한 건(booking) 당 한 줄"로 묶은 목록
  final Map<String, List<_BookingAggRow>> _rowsByCls = {
    '이코노미': [],
    '프리미엄이코노미': [],
    '비즈니스': [],
    '퍼스트': [],
    '기타': [],
  };

  // 검색/필터
  final _emailCtrl = TextEditingController();
  bool _paidOnly = true; // 기본: 결제완료만
  String _classFilter = '전체';
  final _classOptions = const ['전체', '이코노미', '프리미엄이코노미', '비즈니스', '퍼스트', '기타'];

  static const _fallbackRatio = {
    '이코노미': 0.70,
    '프리미엄이코노미': 0.17,
    '비즈니스': 0.10,
    '퍼스트': 0.03,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  int _asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

  String _seatClassOf(String seatCode) {
    if (seatCode.isEmpty) return '기타';
    switch (seatCode[0].toUpperCase()) {
      case 'F':
        return '퍼스트';
      case 'B':
        return '비즈니스';
      case 'P':
        return '프리미엄이코노미';
      case 'E':
        return '이코노미';
      default:
        return '기타';
    }
  }

  Map<String, int> _capFromDoc(Map<String, dynamic> f) {
    final total = _asInt(f['총좌석']);
    final econ = _asInt(f['좌석_이코노미']);
    final prem = _asInt(f['좌석_프리미엄이코노미']);
    final biz  = _asInt(f['좌석_비즈니스']);
    final first= _asInt(f['좌석_퍼스트']);

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
    final diff = total - sum; // 반올림 오차 보정
    e += diff;

    return {
      '이코노미': max(0, e),
      '프리미엄이코노미': max(0, p),
      '비즈니스': max(0, b),
      '퍼스트': max(0, fcls),
    };
  }

  String _pct(int booked, int cap) {
    final r = (cap > 0) ? booked / cap : 0.0;
    return '${(r * 100).toStringAsFixed(1)}%';
  }

  String _won(num v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return '${buf.toString()}원';
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final fs = FirebaseFirestore.instance;

      // 1) 항공편 메타
      final flightSnap =
          await fs.collection(widget.collection).doc(widget.flightId).get();
      if (!flightSnap.exists) {
        setState(() {
          error = '항공편을 찾을 수 없습니다.';
          loading = false;
        });
        return;
      }
      final f = flightSnap.data() as Map<String, dynamic>;
      final cap = _capFromDoc(f);

      // 2) 예약 로드 (aid == flightId)
      final bookings = await fs
          .collection('booking')
          .where('aid', isEqualTo: widget.flightId)
          .get();

      // 초기화
      final bookedMap = <String, int>{
        '이코노미': 0, '프리미엄이코노미': 0, '비즈니스': 0, '퍼스트': 0,
      };
      final revenueByCls = <String, int>{
        '이코노미': 0, '프리미엄이코노미': 0, '비즈니스': 0, '퍼스트': 0,
      };
      int revenueTotal = 0;

      // 등급별 "한 건당 한 줄" 목록
      final rowsByCls = <String, List<_BookingAggRow>>{
        '이코노미': [],
        '프리미엄이코노미': [],
        '비즈니스': [],
        '퍼스트': [],
        '기타': [],
      };

      // 필터
      final qEmail = _emailCtrl.text.trim().toLowerCase();
      final paidOnly = _paidOnly;

      for (final b in bookings.docs) {
        final m = b.data();
        final bid     = (m['bid'] ?? b.id).toString();
        final state   = (m['bState'] ?? '').toString();     // '결제완료', '취소됨'...
        final email   = (m['uEmail'] ?? '').toString();
        final price   = _asInt(m['aPrice']);                 // 예약 총액
        final bDate   = (m['bDate'] ?? '').toString();       // YYYY-MM-DD
        final seats   = (m['bSit'] as List?)?.cast<String>() ?? const <String>[];

        // 이메일 필터
        if (qEmail.isNotEmpty && !email.toLowerCase().contains(qEmail)) {
          continue;
        }
        // 결제완료만 보기
        if (paidOnly && state != '결제완료') {
          continue;
        }

        // 이 예약에서 좌석을 등급별로 묶기
        final perClassSeats = <String, List<String>>{};
        for (final s in seats) {
          final cls = _seatClassOf(s);
          perClassSeats.putIfAbsent(cls, () => <String>[]).add(s);
        }

        // 좌석수 카운트(등급별)
        perClassSeats.forEach((cls, seatList) {
          if (bookedMap.containsKey(cls)) {
            bookedMap[cls] = (bookedMap[cls] ?? 0) + seatList.length;
          }
        });

        // 수익: 결제완료만 좌석수로 균등배분
        if (state == '결제완료' && seats.isNotEmpty && price > 0) {
          final perSeat = price / seats.length;
          perClassSeats.forEach((cls, seatList) {
            if (!revenueByCls.containsKey(cls)) return;
            revenueByCls[cls] =
                (revenueByCls[cls] ?? 0) + (perSeat * seatList.length).round();
          });
          revenueTotal += price;
        }

        // === 화면 표시용 행 만들기 ===
        // "같이 예매한 이메일/날짜/금액/상태"를 한 번만 보여주고,
        // 해당 등급 섹션 안에서는 좌석만 나열한다.
        perClassSeats.forEach((cls, seatList) {
          rowsByCls[cls]!.add(
            _BookingAggRow(
              bookingId: bid,
              email: email,
              date: bDate,
              totalPrice: price,
              state: state,
              seatsOfThisClass: seatList, // 이 등급에 속한 좌석들만
            ),
          );
        });
      }

      // 각 등급별 목록 정렬: (예약일 오름차순, 이메일 오름차순)
      for (final k in rowsByCls.keys) {
        rowsByCls[k]!.sort((a,b) {
          final byDate = a.date.compareTo(b.date);
          if (byDate != 0) return byDate;
          return a.email.compareTo(b.email);
        });
      }

      setState(() {
        _flight = f;
        _cap = cap;
        _booked = bookedMap;
        _revenueTotal = revenueTotal;
        _revenueByCls
          ..clear()
          ..addAll(revenueByCls);

        // 표시목록 반영
        _rowsByCls.forEach((k, _) => _rowsByCls[k] = rowsByCls[k] ?? []);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('예매율 상세')),
        body: Center(child: Text('오류: $error')),
      );
    }

    final f = _flight!;
    final title =
        '${(f['운항편명'] ?? f['항공편번호'] ?? f['항공편'] ?? '').toString()} • ${(f['출발지'] ?? '').toString()} → ${(f['목적지'] ?? '').toString()}';

    final totalCap = _cap.values.fold<int>(0, (a,b) => a+b);
    final totalBooked = _booked.values.fold<int>(0, (a,b) => a+b);
    final totalPct = _pct(totalBooked, totalCap);

    final order = const ['퍼스트', '비즈니스', '프리미엄이코노미', '이코노미', '기타'];
    final visibleClasses = _classFilter == '전체'
        ? order
        : order.where((c) => c == _classFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('예매율 상세')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('운항일자: ${(f['운항일자'] ?? '').toString()}'),
          Text('총 좌석: $totalCap / 총 예매: $totalBooked ($totalPct)'),
          const SizedBox(height: 12),

          // ===== 상단 필터 =====
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            isDense: true,
                            prefixIcon: Icon(Icons.search),
                            hintText: '이메일 검색',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _load(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: _classFilter,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: '등급',
                            border: OutlineInputBorder(),
                          ),
                          items: _classOptions
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _classFilter = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('결제완료만'),
                        selected: _paidOnly,
                        onSelected: (v) => setState(() => _paidOnly = v),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('적용'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ===== 수익 카드 =====
          Card(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('수익 (결제완료 기준)', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('총 수익: ${_won(_revenueTotal)}'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['이코노미','프리미엄이코노미','비즈니스','퍼스트'].map((cls) {
                      final v = _revenueByCls[cls] ?? 0;
                      return Chip(label: Text('$cls: ${_won(v)}'));
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // ===== 등급별 — "예약건 기준 한 줄" =====
          ...visibleClasses.map((cls) {
            final cap = _cap[cls] ?? 0;
            final bookedSeats = _booked[cls] ?? 0;
            final pct = _pct(bookedSeats, cap);
            final rows = _rowsByCls[cls] ?? const <_BookingAggRow>[];

            if (rows.isEmpty && bookedSeats == 0 && cap == 0) {
              return const SizedBox.shrink();
            }

            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Row(
                children: [
                  Text(cls, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Text('예매좌석 $bookedSeats / 좌석 $cap  ($pct)'),
                ],
              ),
              children: [
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('결과 없음'),
                  )
                else
                  Column(
                    children: rows.map((r) {
                      final seatStr = r.seatsOfThisClass.join(', ');
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(r.email),
                        subtitle: Text('예약일: ${r.date}  •  상태: ${r.state}\n좌석: $seatStr'),
                        trailing: (r.totalPrice > 0 && r.state == '결제완료')
                            ? Text(_won(r.totalPrice),
                                style: const TextStyle(fontWeight: FontWeight.w600))
                            : const SizedBox.shrink(),
                      );
                    }).toList(),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ===== 내부 모델(한 예약건 단위로 묶은 Row) =====
class _BookingAggRow {
  final String bookingId;            // bid
  final String email;
  final String date;                 // bDate
  final int totalPrice;              // aPrice
  final String state;                // bState
  final List<String> seatsOfThisClass; // 이 등급에 속한 좌석 목록만

  _BookingAggRow({
    required this.bookingId,
    required this.email,
    required this.date,
    required this.totalPrice,
    required this.state,
    required this.seatsOfThisClass,
  });
}