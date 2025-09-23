
import 'package:flutter/material.dart';
import 'package:travel_web/models/rateraw.dart';

class RateList extends StatelessWidget {
  final List<RateRow> rows;
  const RateList({required this.rows, super.key});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('데이터가 없습니다.'));
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = rows[i];
        final pct = (r.rate * 100).toStringAsFixed(1);
        return ListTile(
          title: Text('${r.flightNo} • ${r.origin} → ${r.dest} • ${r.date}'),
          subtitle: Text('${r.seatClass}  예약 ${r.booked}/${r.capacity}  •  예매율 $pct%'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // 필요 시 디테일로 점프
            // Navigator.push(context, MaterialPageRoute(builder: (_) => AirplaneStartDetailPage(docId: r.flightId)));
          },
        );
      },
    );
  }
}