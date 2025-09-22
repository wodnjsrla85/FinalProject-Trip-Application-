// inquiry_answer_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InquiryAnswerPage extends StatefulWidget {
  const InquiryAnswerPage({super.key, required this.docId});

  final String docId;

  @override
  State<InquiryAnswerPage> createState() => _InquiryAnswerPageState();
}

class _InquiryAnswerPageState extends State<InquiryAnswerPage> {
  bool _saving = false;

  final _titleCtrl = TextEditingController();      // 읽기 전용
  final _contentCtrl = TextEditingController();    // 읽기 전용
  final _userEmailCtrl = TextEditingController();  // 읽기 전용(칩으로만 표시)
  final _adminEmailCtrl = TextEditingController(); // ✅ 읽기 전용으로 변경
  final _replyCtrl = TextEditingController();      // 편집 가능

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _userEmailCtrl.dispose();
    _adminEmailCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  String _safeStr(dynamic v) => (v ?? '').toString();

  DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    final s = _safeStr(v);
    final dt = DateTime.tryParse(s);
    return dt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _saveAsDone() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{
        // aEmail은 readOnly로 전환했지만 서버에는 반영(변경 없음)
        'aEmail': _adminEmailCtrl.text.trim(),
        'reply': _replyCtrl.text.trim(),
        'replyDate': DateTime.now().toIso8601String(),
        'state': '답변완료',
      };

      await FirebaseFirestore.instance
          .collection('inquery')
          .doc(widget.docId)
          .update(updates);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("저장했고 상태를 '답변완료'로 변경했습니다.")),
      );
      Navigator.pop(context, true); // true: 변경됨
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('inquery')
          .doc(widget.docId)
          .snapshots(),
      builder: (context, snap) {
        // AppBar 안에서도 상태(답변완료 여부)를 알아야 하므로
        String currentState = '';
        if (snap.hasData && snap.data!.exists) {
          final m = snap.data!.data()!;
          currentState = _safeStr(m['state']);
        }

        final isDone = currentState == '답변완료';

        return Scaffold(
          appBar: AppBar(
            title: const Text('문의 답변'),
            actions: [
              // ✅ 이미 답변완료이면 버튼 숨김
              if (!isDone)
                FilledButton.icon(
                  onPressed: _saving ? null : _saveAsDone,
                  icon: const Icon(Icons.done_all),
                  label: const Text("답변완료"),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: snap.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : (!snap.hasData || !snap.data!.exists)
                  ? const Center(child: Text('문서를 찾을 수 없습니다.'))
                  : _buildBodyWithData(snap.data!, isDone),
        );
      },
    );
  }

  Widget _buildBodyWithData(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool isDone,
  ) {
    final m = doc.data()!;
    // 초기 바인딩 (빈 컨트롤러일 때만 세팅)
    if (_titleCtrl.text.isEmpty) _titleCtrl.text = _safeStr(m['title']);
    if (_contentCtrl.text.isEmpty) _contentCtrl.text = _safeStr(m['content']);
    if (_userEmailCtrl.text.isEmpty) _userEmailCtrl.text = _safeStr(m['uEmail']);
    if (_adminEmailCtrl.text.isEmpty) _adminEmailCtrl.text = _safeStr(m['aEmail']);
    if (_replyCtrl.text.isEmpty) _replyCtrl.text = _safeStr(m['reply']);

    final date = _asDate(m['date']);
    final replyDate = _asDate(m['replyDate']);
    final currentState = _safeStr(m['state']).isEmpty ? '처리중' : _safeStr(m['state']);

    return AbsorbPointer(
      absorbing: _saving,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 안내 배너 (답변완료 시)
            if (isDone)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text("이 문의는 '답변완료' 상태입니다.")),
                  ],
                ),
              ),

            // 메타 정보
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.mail),
                  label: Text('사용자: ${_userEmailCtrl.text}'),
                ),
                Chip(
                  avatar: const Icon(Icons.schedule),
                  label: Text(
                    '문의일: ${date.millisecondsSinceEpoch == 0 ? '-' : date.toLocal().toString().substring(0, 19)}',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.flag),
                  label: Text('현재 상태: $currentState'),
                ),
                if (replyDate.millisecondsSinceEpoch > 0)
                  Chip(
                    avatar: const Icon(Icons.reply),
                    label: Text('마지막 답변일: ${replyDate.toLocal().toString().substring(0, 19)}'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 제목(읽기 전용)
            TextField(
              controller: _titleCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // 문의 내용(읽기 전용)
            TextField(
              controller: _contentCtrl,
              readOnly: true,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: '문의 내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ 담당자 이메일 (읽기 전용)
            TextField(
              controller: _adminEmailCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '담당자 이메일 (aEmail)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // 답변 입력 (편집 가능 — 답변완료 상태라도 내용은 확인/수정 가능하게 유지하려면 readOnly: false)
            TextField(
              controller: _replyCtrl,
              minLines: 6,
              maxLines: 12,
              readOnly: false,
              decoration: const InputDecoration(
                labelText: '답변 내용 (reply)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),

            // ⛔ 하단 일반 저장 버튼 제거 (요청사항)
            // '답변완료' 버튼은 AppBar에 있고, 상태가 답변완료면 자동으로 숨김 처리됨.
          ],
        ),
      ),
    );
  }
}