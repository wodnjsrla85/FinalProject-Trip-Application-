import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/model/airport.dart';
import 'package:travel_app/model/travel_package.dart';
import 'package:travel_app/view/home_booking/booking_page.dart';
import 'package:travel_app/view/home_booking/package_detail.dart';
import 'package:travel_app/vm/save_provider.dart';

class MyFavoritePage extends StatefulWidget {
  const MyFavoritePage({super.key});

  @override
  State<MyFavoritePage> createState() => _MyFavoritePageState();
}

class _MyFavoritePageState extends State<MyFavoritePage> {
  List<String> flights = [];
  List<String> packages = [];
  bool isLoading = true;

  final saveProvider = SaveProvider();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection("save").doc(user.email).get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      setState(() {
        flights = List<String>.from(data["flights"] ?? []);
        packages = List<String>.from(data["packages"] ?? []);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<Airport?> _getFlightById(String flightId) async {
    final startDoc = await FirebaseFirestore.instance
        .collection("airplane_start")
        .doc(flightId)
        .get();

    if (startDoc.exists) {
      return Airport.fromMap(startDoc.data()!, startDoc.id);
    }

    final endDoc = await FirebaseFirestore.instance
        .collection("airplane_end")
        .doc(flightId)
        .get();

    if (endDoc.exists) {
      return Airport.fromMap(endDoc.data()!, endDoc.id);
    }

    return null;
  }

  Future<TravelPackage?> _getPackageById(String packageId) async {
    final doc =
        await FirebaseFirestore.instance.collection("package").doc(packageId).get();

    if (doc.exists) {
      return TravelPackage.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (flights.isEmpty && packages.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("저장된 항목이 없습니다.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("내 북마크")),
      body: ListView(
        children: [
          if (flights.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("✈ 항공편",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...flights.map((id) => FutureBuilder<Airport?>(
                  future: _getFlightById(id),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const ListTile(title: Text("불러오는 중..."));
                    }
                    final flight = snap.data;
                    if (flight == null) {
                      return ListTile(title: Text("항공편($id) 정보를 찾을 수 없습니다."));
                    }
                    return ListTile(
  leading: const Icon(Icons.flight, color: Colors.blue),
  title: Text("${flight.start} → ${flight.end}"),
  subtitle: Text(
      "${flight.company} ${flight.name} (${flight.date} ${flight.time})"),
  trailing: IconButton(
    icon: const Icon(Icons.bookmark_remove, color: Colors.red),
    onPressed: () async {
      await saveProvider.toggleFlight(flight.id);
      setState(() {
        flights.remove(flight.id); // UI 즉시 반영
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("항공편 북마크 해제됨")),
      );
    },
  ),
  onTap: () {
    // 항공편 상세 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(
          flight: flight,
          passengerCount: 1, // 기본값, 필요시 선택 기능 추가 가능
        ),
      ),
    );
  },
);

                  },
                )),
          ],
          if (packages.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("패키지",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...packages.map((id) => FutureBuilder<TravelPackage?>(
                  future: _getPackageById(id),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const ListTile(title: Text("불러오는 중..."));
                    }
                    final pkg = snap.data;
                    if (pkg == null) {
                      return ListTile(title: Text("패키지($id) 정보를 찾을 수 없습니다."));
                    }
                    return ListTile(
  leading: pkg.images.isNotEmpty
      ? Image.network(pkg.images.first,
          width: 50, height: 50, fit: BoxFit.cover)
      : const Icon(Icons.card_travel, color: Colors.purple),
  title: Text(pkg.pName),
  subtitle: Text("₩${pkg.pPrice} • ${pkg.pCount}명"),
  trailing: IconButton(
    icon: const Icon(Icons.bookmark_remove, color: Colors.red),
    onPressed: () async {
      await saveProvider.togglePackage(pkg.id);
      setState(() {
        packages.remove(pkg.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("패키지 북마크 해제됨")),
      );
    },
  ),
  onTap: () {
    // 패키지 상세 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackageDetailPage(package: pkg),
      ),
    );
  },
);

                  },
                )),
          ],
        ],
      ),
    );
  }
}
