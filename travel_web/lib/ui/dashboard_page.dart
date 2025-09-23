import 'package:flutter/material.dart';
import 'package:travel_web/ui/pages/list/airplane_end_list_page.dart';
import 'package:travel_web/ui/pages/list/airplane_start_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('항공 대시보드'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.flight_takeoff), text: '출발 (Start)'),
              Tab(icon: Icon(Icons.flight_land), text: '도착 (End)'),
            ],
          ),
        ),
        body: const TabBarView(
          // ✨ 페이지 전환 없이 한 화면에서 탭으로 교체
          children: [
            AirplaneStartListPage(),
            AirplaneEndListPage(),
          ],
        ),
      ),
    );
  }
}