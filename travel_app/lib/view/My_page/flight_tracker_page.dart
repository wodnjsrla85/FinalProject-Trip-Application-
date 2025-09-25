import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FlightTrackerPage extends StatefulWidget {
  const FlightTrackerPage({super.key});

  @override
  State<FlightTrackerPage> createState() => _FlightTrackerPageState();
}

class _FlightTrackerPageState extends State<FlightTrackerPage> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => setState(() => isLoading = true),
        onPageFinished: (url) => setState(() => isLoading = false),
      ))
      ..loadRequest(Uri.parse('https://map.opensky-network.org/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // ✅ 밝은 배경
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          '실시간 항공기 추적',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 웹뷰
          WebViewWidget(controller: controller),

          // 로딩 인디케이터 (밝은 스타일)
          if (isLoading)
            Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6), // ✅ 블루 포인트
                ),
              ),
            ),
        ],
      ),
    );
  }
}
