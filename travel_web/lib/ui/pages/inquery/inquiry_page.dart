// inquiry_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'inquiry_answer_page.dart';

class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key});

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Object? _error;

  late TabController _tab;

  final _fmt = DateFormat('yyyy.MM.dd HH:mm');

  List<_Inquiry> _all = [];
  List<_Inquiry> _pending = [];
  List<_Inquiry> _done = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _safeStr(dynamic v) => (v ?? '').toString();

  DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    final s = _safeStr(v);
    final dt = DateTime.tryParse(s);
    if (dt != null) return dt;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final qs = await FirebaseFirestore.instance
          .collection('inquery')
          .where('to', isEqualTo: '항공사') // 단일 where → 인덱스 불필요
          .get();

      final list = <_Inquiry>[];
      for (final d in qs.docs) {
        final m = d.data();
        list.add(
          _Inquiry(
            id: d.id,
            title: _safeStr(m['title']),
            content: _safeStr(m['content']),
            userEmail: _safeStr(m['uEmail']),
            adminEmail: _safeStr(m['aEmail']),
            state: _safeStr(m['state']), // '답변완료' or 기타
            date: _asDate(m['date']),
            reply: _safeStr(m['reply']),
            replyDate: _asDate(m['replyDate']),
          ),
        );
      }

      // 최신순
      list.sort((a, b) => b.date.compareTo(a.date));

      final done = <_Inquiry>[];
      final pending = <_Inquiry>[];
      for (final x in list) {
        if (x.state == '답변완료') {
          done.add(x);
        } else {
          pending.add(x);
        }
      }

      setState(() {
        _all = list;
        _done = done;
        _pending = pending;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('문의'),
          bottom: TabBar(
            controller: _tab,
            tabs: const [
              Tab(icon: Icon(Icons.mark_chat_unread), text: '문의 처리중'),
              Tab(icon: Icon(Icons.check_circle), text: '문의 완료'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null
                ? Center(child: Text('오류: $_error'))
                : TabBarView(
                    controller: _tab,
                    children: [
                      // 처리중 탭 (그대로)
                      _InquiryListView(
                        items: _pending,
                        fmt: _fmt,
                        emptyText: '처리중 문의가 없습니다.',
                        icon: Icons.mark_chat_unread,
                        color: Colors.orange,
                        onRefresh: _refresh,
                      ),
                      // ✅ 완료 탭 (이메일/날짜 검색 지원)
                      _InquiryDoneTab(
                        items: _done,
                        fmt: _fmt,
                        onRefresh: _refresh,
                      ),
                    ],
                  )),
      ),
    );
  }
}

class _Inquiry {
  final String id;
  final String title;
  final String content;
  final String userEmail;
  final String adminEmail;
  final String state; // '답변완료' or 기타
  final DateTime date;
  final String reply;
  final DateTime replyDate;

  _Inquiry({
    required this.id,
    required this.title,
    required this.content,
    required this.userEmail,
    required this.adminEmail,
    required this.state,
    required this.date,
    required this.reply,
    required this.replyDate,
  });
}

/// ===== 공용 리스트 뷰 (처리중 탭용) =====
class _InquiryListView extends StatelessWidget {
  final List<_Inquiry> items;
  final DateFormat fmt;
  final String emptyText;
  final IconData icon;
  final Color color;
  final Future<void> Function() onRefresh;

  const _InquiryListView({
    required this.items,
    required this.fmt,
    required this.emptyText,
    required this.icon,
    required this.color,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('처리중 문의가 없습니다.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 8),
        itemBuilder: (context, i) {
          final it = items[i];
          final isDone = it.state == '답변완료';
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(it.title.isEmpty ? '(제목 없음)' : it.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${fmt.format(it.date)} · ${it.userEmail}'),
            trailing: Chip(
              label: Text(it.state),
              backgroundColor: color.withOpacity(0.12),
              side: BorderSide.none,
              labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              final goToAnswer = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(it.title.isEmpty ? '(제목 없음)' : it.title),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('작성일: ${fmt.format(it.date)}'),
                        Text('작성자: ${it.userEmail}'),
                        const SizedBox(height: 8),
                        const Text('문의 내용', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(it.content.isEmpty ? '(내용 없음)' : it.content),
                        const SizedBox(height: 12),
                        const Divider(),
                        const Text('답변', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (it.reply.isEmpty)
                          const Text('(아직 답변이 없습니다)') else Text(it.reply),
                        if (it.replyDate.millisecondsSinceEpoch > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('답변일: ${fmt.format(it.replyDate)}'),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('닫기'),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: Icon(isDone ? Icons.visibility : Icons.reply),
                      label: Text(isDone ? '문의보기' : '답변하기'),
                    ),
                  ],
                ),
              );

              if (goToAnswer == true) {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InquiryAnswerPage(docId: it.id),
                  ),
                );
                if (changed == true) {
                  await onRefresh();
                }
              }
            },
          );
        },
      ),
    );
  }
}

/// ===== 완료 탭(검색/필터 포함) =====
class _InquiryDoneTab extends StatefulWidget {
  const _InquiryDoneTab({
    required this.items,
    required this.fmt,
    required this.onRefresh,
  });

  final List<_Inquiry> items;
  final DateFormat fmt;
  final Future<void> Function() onRefresh;

  @override
  State<_InquiryDoneTab> createState() => _InquiryDoneTabState();
}

class _InquiryDoneTabState extends State<_InquiryDoneTab> {
  final _emailCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<_Inquiry> _filtered = [];

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  @override
  void didUpdateWidget(covariant _InquiryDoneTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) {
      setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) {
      // 종료일은 하루 끝(23:59:59)로 맞춰 검색 편의 보장
      setState(() => _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
    }
  }

  void _applyFilter() {
    final q = _emailCtrl.text.trim().toLowerCase();
    final s = _startDate;
    final e = _endDate;

    final out = <_Inquiry>[];
    for (final it in widget.items) {
      // 이메일 필터(uEmail 또는 aEmail)
      final emailHit = q.isEmpty ||
          it.userEmail.toLowerCase().contains(q) ||
          it.adminEmail.toLowerCase().contains(q);

      // 날짜 범위
      final dateHit = (s == null && e == null) ||
          (s != null && e == null && it.date.isAfter(s.subtract(const Duration(seconds: 1)))) ||
          (s == null && e != null && it.date.isBefore(e.add(const Duration(seconds: 1)))) ||
          (s != null && e != null && it.date.isAfter(s.subtract(const Duration(seconds: 1))) && it.date.isBefore(e.add(const Duration(seconds: 1))));

      if (emailHit && dateHit) out.add(it);
    }
    setState(() {
      _filtered = out;
    });
  }

  void _reset() {
    setState(() {
      _emailCtrl.clear();
      _startDate = null;
      _endDate = null;
      _filtered = widget.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('yyyy.MM.dd');

    return Column(
      children: [
        // 🔎 필터 바
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: '이메일 검색 (고객/담당자)',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickStart,
                    icon: const Icon(Icons.event),
                    label: Text(_startDate == null ? '시작일' : fmtDate.format(_startDate!)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: _pickEnd,
                    icon: const Icon(Icons.event_available),
                    label: Text(_endDate == null ? '종료일' : fmtDate.format(_endDate!)),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.filter_alt),
                label: const Text('적용'),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text('초기화'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '새로고침',
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 리스트
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: _filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('검색 결과가 없습니다.')),
                    ],
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, i) {
                      final it = _filtered[i];
                      return ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(it.title.isEmpty ? '(제목 없음)' : it.title,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${widget.fmt.format(it.date)} · ${it.userEmail}'),
                        trailing: Chip(
                          label: Text(it.state),
                          backgroundColor: Colors.green.withOpacity(0.12),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                        onTap: () async {
                          final goToAnswer = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(it.title.isEmpty ? '(제목 없음)' : it.title),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('작성일: ${widget.fmt.format(it.date)}'),
                                    Text('작성자: ${it.userEmail}'),
                                    const SizedBox(height: 8),
                                    const Text('문의 내용', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(it.content.isEmpty ? '(내용 없음)' : it.content),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const Text('답변', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    if (it.reply.isEmpty)
                                      const Text('(아직 답변이 없습니다)') else Text(it.reply),
                                    if (it.replyDate.millisecondsSinceEpoch > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text('답변일: ${widget.fmt.format(it.replyDate)}'),
                                      ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('닫기'),
                                ),
                                // 완료 탭이므로 기본 버튼은 '문의보기'
                                FilledButton.icon(
                                  onPressed: () => Navigator.pop(context, true),
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('문의보기'),
                                ),
                              ],
                            ),
                          );
                          if (goToAnswer == true) {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InquiryAnswerPage(docId: it.id),
                              ),
                            );
                            if (changed == true) {
                              await widget.onRefresh();
                              _applyFilter(); // 최신 데이터로 필터 재적용
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}