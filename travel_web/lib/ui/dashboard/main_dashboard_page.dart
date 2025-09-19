// lib/ui/pages/dashboard/main_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:travel_web/ui/flight_hub_page.dart';
import 'package:travel_web/ui/pages/booking/booking_rate_page.dart';
import 'package:travel_web/ui/widgets/booking_lineplot_syncfusion.dart';

class MainDashboardPage extends StatelessWidget {
  const MainDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    void goBooking() {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingRatePage()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('메인 대시보드')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 월별 일자 직접/패키지 예매량 라인플롯 =====
          BookingLineplotSyncfusion(onGoBooking: goBooking),

          const SizedBox(height: 16),

          // ===== 하단 액션 버튼 영역 =====
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DashButton(
                icon: Icons.flight_takeoff,
                label: '항공편 (출발/도착)',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FlightHubPage()),
                ),
              ),
              _DashButton(
                icon: Icons.analytics,
                label: '예매 분석',
                onTap: goBooking,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DashButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 80,
      child: OutlinedButton(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}