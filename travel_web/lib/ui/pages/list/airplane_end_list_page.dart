import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_web/models/airplane_end.dart';
import 'package:travel_web/ui/pages/add/airplane_end_create_page.dart';
import 'package:travel_web/utils/flight_meta.dart';
import '../../../data/airplane_end_repository.dart';
import '../detail/airplane_end_detail_page.dart';


enum RouteFilter { all, direct, transfer }

class AirplaneEndListPage extends StatefulWidget {
  const AirplaneEndListPage({super.key});

  @override
  State<AirplaneEndListPage> createState() => _AirplaneEndListPageState();
}

class _AirplaneEndListPageState extends State<AirplaneEndListPage> {
  final repo = AirplaneEndRepository();

  /// 기본값: 인천(ICN)으로 들어오는 도착편
  String destination = 'ICN';
  String? origin; // 출발지 필터(자동완성 대상)
  RouteFilter _filter = RouteFilter.all;

  // infinite scroll
  final _scroll = ScrollController();
  final _items = <QueryDocumentSnapshot<AirplaneEnd>>[];
  DocumentSnapshot<AirplaneEnd>? _last;
  bool _loading = false;
  bool _hasMore = true;
  static const _pageSize = 20;

  // 검색(자동완성)용 컨트롤러
  final _originCtrl = TextEditingController();

  // IATA 후보
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
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
          !_loading && _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _originCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      var query = repo.baseQuery(
        destination: destination,
        origin: origin,
        directOnly: _filter == RouteFilter.direct ? true : null,
      );
      if (_filter == RouteFilter.transfer) {
        query = query.where('직항여부', isEqualTo: 0);
      }

      final snap = await repo.fetchPage(query: query, last: _last, limit: _pageSize);
      if (snap.docs.isNotEmpty) {
        _last = snap.docs.last;
        _items.addAll(snap.docs);
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _hasMore = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로드 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
          // 새로고침
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          // 전체/직항/경유 세그먼트
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
        // ✅ AppBar 하단에 자동완성 검색 바 (출발지)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Text('출발지:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue v) {
                      final q = v.text.trim().toUpperCase();
                      if (q.isEmpty) return const Iterable<String>.empty();
                      return _iataOptions.where((opt) => opt.startsWith(q));
                    },
                    fieldViewBuilder: (context, textController, focusNode, _) {
                      // 초기 동기화(1회)
                      if (textController.text.isEmpty && _originCtrl.text.isNotEmpty) {
                        textController.text = _originCtrl.text;
                        textController.selection = TextSelection.fromPosition(
                          TextPosition(offset: textController.text.length),
                        );
                      }
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: '예: NRT, CAN, TFU',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: (textController.text.isEmpty)
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    textController.clear();
                                    _applyOrigin(null);
                                  },
                                ),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          _originCtrl.text = v.toUpperCase();
                        },
                        onSubmitted: (v) => _applyOrigin(v),
                      );
                    },
                    onSelected: (selection) => _applyOrigin(selection),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('데이터가 없습니다'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('새로고침'),
                  ),
                ],
              ),
            )
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
                      title: Text('${a.flightNo} • ${a.airline} • ${a.aircraft}'),
                      subtitle: Text(
                        '${a.arrivalDate}  ${a.origin}(${a.terminal}) ${a.departureTime} → ${a.destination}  '
                        '/ ${a.isDirect ? "직항" : a.directType} / ${a.status}',
                      ),
                      trailing: Text('좌석 ${a.totalSeats}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AirplaneEndDetailPage(docId: _items[i].id),
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
            MaterialPageRoute(builder: (_) => const AirplaneEndCreatePage()),
          );
          if (created == true && mounted) {
            await _refresh();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('도착편이 추가되었습니다.')));
          }
        },
      ),
    );
  }
}