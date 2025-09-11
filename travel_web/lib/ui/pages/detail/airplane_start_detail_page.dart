import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel_web/ui/pages/edit/airplane_start_edit_page.dart';
import '../../../data/airplane_start_repository.dart';
import '../../../models/airplane_start.dart';
import '../../widgets/fare_chips_start.dart';

class AirplaneStartDetailPage extends StatefulWidget {
  final String docId;
  const AirplaneStartDetailPage({super.key, required this.docId});

  @override
  State<AirplaneStartDetailPage> createState() => _AirplaneStartDetailPageState();
}

class _AirplaneStartDetailPageState extends State<AirplaneStartDetailPage> {
  final repo = AirplaneStartRepository();
  AirplaneStart? data;
  Object? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await repo.fetchById(widget.docId);
      setState(() {
        data = v;
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
        content: const Text('이 출발편 정보를 삭제할까요? 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection('airplane_start').doc(widget.docId).delete();
      if (!mounted) return;
      Navigator.pop(context, true); // 목록으로 복귀 + 성공 신호
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  Future<void> _edit() async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AirplaneStartEditPage(docId: widget.docId)),
    );
    if (edited == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정되었습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Text('오류: $error')));
    if (data == null) return const Scaffold(body: Center(child: Text('데이터 없음')));

    final a = data!;
    return Scaffold(
      appBar: AppBar(
        title: Text(a.flightNo),
        actions: [
          IconButton(tooltip: '수정', icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(tooltip: '삭제', icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${a.airline} • ${a.aircraft}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${a.origin}(${a.terminal}) ${a.departureTime} → ${a.destination} / 도착 ${a.arrivalTime}'),
          Text('운항일자: ${a.flightDate} / 상태: ${a.status} / 직항여부: ${a.isDirect ? '직항' : a.directType}'),
          Text('예상 소요: ${a.durationHHMM} (${a.durationMin}분) / 좌석: ${a.totalSeats}'),
          const SizedBox(height: 16),
          const Text('비수기 평균 운임'),
          FareChips(a: a, peak: false),
          const SizedBox(height: 12),
          const Text('성수기 평균 운임'),
          FareChips(a: a, peak: true),
        ],
      ),
    );
  }
}