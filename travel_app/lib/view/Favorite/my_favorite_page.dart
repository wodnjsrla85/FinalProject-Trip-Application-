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
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF003366))),
      );
    }

    if (flights.isEmpty && packages.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Text(
            "저장된 항목이 없습니다.",
            style: TextStyle(color: Color(0xFF475569), fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (flights.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "✈ 항공편",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
              ),
              ...flights.map((id) => FutureBuilder<Airport?>(
                    future: _getFlightById(id),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return _buildLoadingCard("항공편 불러오는 중...");
                      }
                      final flight = snap.data;
                      if (flight == null) {
                        return _buildErrorCard("항공편($id) 정보를 찾을 수 없습니다.");
                      }
                      return _buildFlightCard(flight);
                    },
                  )),
            ],
            if (packages.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.0),
                      child: Icon(Icons.card_travel, color: Color(0xFF003366), size: 18,),
                    ),
                    Text(
                      " 패키지",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ],
                ),
              ),
              ...packages.map((id) => FutureBuilder<TravelPackage?>(
                    future: _getPackageById(id),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return _buildLoadingCard("패키지 불러오는 중...");
                      }
                      final pkg = snap.data;
                      if (pkg == null) {
                        return _buildErrorCard("패키지($id) 정보를 찾을 수 없습니다.");
                      }
                      return _buildPackageCard(pkg);
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(String text) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(text, style: const TextStyle(color: Color(0xFF475569))),
      ),
    );
  }

  Widget _buildErrorCard(String text) {
    return Card(
      color: Colors.red.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(text, style: const TextStyle(color: Color(0xFFE11D48))),
      ),
    );
  }

  Widget _buildFlightCard(Airport flight) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.flight, color: Colors.blue),
        ),
        title: Text(
          "${flight.start} → ${flight.end}",
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${flight.company} ${flight.name}\n${flight.date} ${flight.time}",
          style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark, color: Color(0xFFFFD700)),
          onPressed: () async {
            await saveProvider.toggleFlight(flight.id);
            setState(() {
              flights.remove(flight.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("항공편 북마크 해제됨")),
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingPage(flight: flight, passengerCount: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageCard(TravelPackage pkg) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: pkg.images.isNotEmpty
              ? Image.network(pkg.images.first,
                  width: 60, height: 60, fit: BoxFit.cover)
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.purple.withOpacity(0.1),
                  child: const Icon(Icons.card_travel, color: Colors.purple),
                ),
        ),
        title: Text(
          pkg.pName,
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "₩${pkg.pPrice} • 최대 ${pkg.pCount}명",
          style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark, color: Color(0xFFFFD700)),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PackageDetailPage(package: pkg),
            ),
          );
        },
      ),
    );
  }
}
