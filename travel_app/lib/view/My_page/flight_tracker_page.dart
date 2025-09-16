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
      appBar: AppBar(
        title: const Text('실시간 항공기 추적'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}