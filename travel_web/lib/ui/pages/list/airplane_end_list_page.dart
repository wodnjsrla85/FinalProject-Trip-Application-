import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_web/data/airplane_end_repository.dart';
import 'package:travel_web/models/airplane_end.dart';
import 'package:travel_web/ui/pages/add/airplane_end_create_page.dart';
import 'package:travel_web/ui/pages/detail/airplane_end_detail_page.dart';
import 'package:travel_web/utils/flight_meta.dart';

enum RouteFilter { all, direct, transfer }

class AirplaneEndListPage extends StatefulWidget {
  const AirplaneEndListPage({super.key});

  @override
  State<AirplaneEndListPage> createState() => _AirplaneEndListPageState();
}

class _AirplaneEndListPageState extends State<AirplaneEndListPage> {
  final repo = AirplaneEndRepository();

  // 필터 상태
  String? origin;               // 출발지(IATA)
  String? _dateFilter;          // 운항일자
  String? _flightNoFilter;      // 편명

  RouteFilter _filter = RouteFilter.all;

  // infinite scroll
  final _scroll = ScrollController();
  final _items = <QueryDocumentSnapshot<AirplaneEnd>>[];
  DocumentSnapshot<AirplaneEnd>? _last;
  bool _loading = false;
  bool _hasMore = true;
  static const _pageSize = 20;

  // 검색 UI 컨트롤러
  final _originCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _flightNoCtrl = TextEditingController();

  List<String> get _iataOptions {
    final set = {...kFlightTimes.keys, ...kNonstopFromICN};
    final list = set.toList()..sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _originCtrl.dispose();
    _dateCtrl.dispose();
    _flightNoCtrl.dispose();
    super.dispose();
  }

  // ====== 필터/쿼리 ======
  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    try {
      // 기본 쿼리 (destination=ICN 고정, origin=null → 전체 출발지 허용)
      Query<AirplaneEnd> query = repo.baseQuery(
        destination: 'ICN',
        origin: origin,
        directOnly: _filter == RouteFilter.direct ? true : null,
      );

      if (_filter == RouteFilter.transfer) {
        query = query.where('직항여부', isEqualTo: 0);
      }

      if (_dateFilter != null && _dateFilter!.isNotEmpty) {
        query = query.where('운항일자', isEqualTo: _dateFilter);
      }

      if (_flightNoFilter != null && _flightNoFilter!.isNotEmpty) {
        final prefix = _flightNoFilter!;
        final end = prefix.substring(0, prefix.length - 1) +
            String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1);
        query =
            query.orderBy('운항편명').startAt([prefix]).endBefore([end]);
      }

      final snap = await repo.fetchPage(
        query: query,
        last: _last,
        limit: _pageSize,
      );

      for (final doc in snap.docs) {
        final a = doc.data();
        await _checkAndUpdateStatus(doc.id, a);
      }

      if (snap.docs.isNotEmpty) {
        _last = snap.docs.last;
        _items.addAll(snap.docs);
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _hasMore = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로드 오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 운항일자 + 출발시간이 지났으면 상태를 '운행 완료'로 변경
  Future<void> _checkAndUpdateStatus(String docId, AirplaneEnd a) async {
    try {
      final dateParts = a.flightDate.split('-');
      final timeParts = a.departureTime.split(':');
      final depDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      if (DateTime.now().isAfter(depDateTime) && a.status != '운행 완료') {
        await FirebaseFirestore.instance
            .collection('airplane_end')
            .doc(docId)
            .update({'상태': '운행 완료'});
      }
    } catch (_) {
      // 파싱 실패 시 무시
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _last = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  void _applyOrigin(String? code) {
    final v = (code ?? '').trim().toUpperCase();
    setState(() {
      origin = v.isEmpty ? null : v;
      _originCtrl.text = origin ?? '';
    });
    _refresh();
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
      setState(() {
        _dateFilter = s;
        _dateCtrl.text = s;
      });
      _refresh();
    }
  }

  void _clearDate() {
    setState(() {
      _dateFilter = null;
      _dateCtrl.clear();
    });
    _refresh();
  }

  void _applyFlightNo() {
    final s = _flightNoCtrl.text.trim().toUpperCase();
    setState(() => _flightNoFilter = s.isEmpty ? null : s);
    _refresh();
  }

  void _clearFlightNo() {
    _flightNoCtrl.clear();
    setState(() => _flightNoFilter = null);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = !_loading && _items.isEmpty;
    final showLoadingRow = _loading;
    final showNoMoreRow = !_hasMore && _items.isNotEmpty;
    final extraRows = (showLoadingRow || showNoMoreRow) ? 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('도착편 목록 (airplane_end)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SegmentedButton<RouteFilter>(
              segments: const [
                ButtonSegment(value: RouteFilter.all, label: Text('전체')),
                ButtonSegment(value: RouteFilter.direct, label: Text('직항')),
                ButtonSegment(value: RouteFilter.transfer, label: Text('경유')),
              ],
              selected: {_filter},
              showSelectedIcon: false,
              onSelectionChanged: (set) {
                final picked = set.first;
                if (_filter != picked) {
                  setState(() => _filter = picked);
                  _refresh();
                }
              },
            ),
          ),
        ],
        // ✅ 검색바 (출발지 자동완성 + 날짜 + 편명)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 출발지 자동완성
                Row(
                  children: [
                    const SizedBox(
                      width: 64,
                      child: Text('출발지', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue v) {
                          final q = v.text.trim().toUpperCase();
                          if (q.isEmpty) return const Iterable<String>.empty();
                          return _iataOptions.where((opt) => opt.startsWith(q));
                        },
                        fieldViewBuilder: (context, textController, focusNode, _) {
                          if (textController.text.isEmpty && _originCtrl.text.isNotEmpty) {
                            textController.text = _originCtrl.text;
                          }
                          return TextField(
                            controller: textController,
                            focusNode: focusNode,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: '예: LAX, JFK',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (v) => _applyOrigin(v),
                          );
                        },
                        onSelected: (s) => _applyOrigin(s),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 날짜 + 편명
                Row(
                  children: [
                    const Text('날짜'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: _dateFilter == null
                              ? null
                              : IconButton(icon: const Icon(Icons.clear), onPressed: _clearDate),
                          border: const OutlineInputBorder(),
                        ),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('편명'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _flightNoCtrl,
                        decoration: InputDecoration(
                          hintText: 'EX) KE123',
                          suffixIcon: _flightNoCtrl.text.isEmpty
                              ? null
                              : IconButton(icon: const Icon(Icons.clear), onPressed: _clearFlightNo),
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _applyFlightNo(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: isEmpty
          ? const Center(child: Text('데이터가 없습니다'))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                controller: _scroll,
                itemCount: _items.length + extraRows,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  if (i < _items.length) {
                    final a = _items[i].data();
                    return ListTile(
                      title: Text('${a.flightNo} • ${a.airline}'),
                      subtitle: Text(
                          '${a.flightDate} ${a.origin}(${a.terminal}) ${a.departureTime} → ${a.destination} / ${a.status}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AirplaneEndDetailPage(docId: _items[i].id),
                          ),
                        );
                      },
                    );
                  }
                  if (showLoadingRow) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (showNoMoreRow) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('더 이상 없음')),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('도착편 추가'),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const AirplaneEndCreatePage()),
          );
          if (created == true && mounted) {
            await _refresh();
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('도착편이 추가되었습니다.')));
          }
        },
      ),
    );
  }
}