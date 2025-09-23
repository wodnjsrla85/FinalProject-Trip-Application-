// lib/ui/widgets/booking_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingPanel extends StatefulWidget {
  final String flightDocId;
  const BookingPanel({super.key, required this.flightDocId});

  @override
  State<BookingPanel> createState() => _BookingPanelState();
}

class _BookingPanelState extends State<BookingPanel> {
  final _search = TextEditingController();
  String _query = '';

  static const _classes = ['이코노미', '프리미엄이코노미', '비즈니스', '퍼스트'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('예매 현황', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: '이메일 검색',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () { _search.clear(); setState(() => _query = ''); },
            ),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),

        // 등급별 확장 패널
        ..._classes.map((cls) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: fs.collection('bookings')
              .where('flightDocId', isEqualTo: widget.flightDocId)
              .where('seatClass', isEqualTo: cls)
              .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }
              final all = snap.data!.docs.map((d) => (d.data()['email'] ?? '').toString()).toList();
              final filtered = _query.isEmpty
                  ? all
                  : all.where((e) => e.toLowerCase().contains(_query)).toList();

              return ExpansionTile(
                title: Text('$cls  •  ${filtered.length}/${all.length}명'),
                children: [
                  if (filtered.isEmpty)
                    const ListTile(title: Text('검색 결과가 없습니다.')),
                  ...filtered.map((e) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.person),
                    title: Text(e),
                  )),
                ],
              );
            },
          );
        }),
      ],
    );
  }
}