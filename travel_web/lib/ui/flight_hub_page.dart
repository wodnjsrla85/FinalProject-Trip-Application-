// lib/ui/pages/flights/flight_hub_page.dart
import 'package:flutter/material.dart';
import 'package:travel_web/ui/pages/list/airplane_end_list_page.dart';
import 'package:travel_web/ui/pages/list/airplane_start_list_page.dart';
import 'package:travel_web/ui/widgets/navtile.dart';

class FlightHubPage extends StatelessWidget {
  const FlightHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('항공편')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            NavTile(
              icon: Icons.flight_takeoff,
              title: '출발편(airplane_start)',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AirplaneStartListPage())),
            ),
            const SizedBox(height: 12),
            NavTile(
              icon: Icons.flight_land,
              title: '도착편(airplane_end)',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AirplaneEndListPage())),
            ),
          ],
        ),
      ),
    );
  }
}