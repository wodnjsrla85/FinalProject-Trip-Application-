// lib/ui/widgets/rate_overall_list.dart
import 'package:flutter/material.dart';
import 'package:travel_web/models/rate_overall.dart';
import 'package:travel_web/ui/pages/booking/booking_rate_detail_page.dart';

class RateOverallList extends StatelessWidget {
  final List<RateRowOverall> rows;
  const RateOverallList({super.key, required this.rows});

  String _pct(double r) => '${(r * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('결과가 없습니다.'));
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final r = rows[i];
        return ListTile(
          title: Text('${r.flightNo} • ${r.origin} → ${r.dest}'),
          subtitle: Text('운항일자: ${r.date} / 예매: ${r.booked}/${r.capacity} (${_pct(r.rate)})'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context, // ✅ 바깥 build의 context 사용
              MaterialPageRoute(
                builder: (_) => BookingRateDetailPage(
                  flightId: r.flightId,
                  collection: r.collection,
                ),
              ),
            );
          },
        );
      },
    );
  }
}