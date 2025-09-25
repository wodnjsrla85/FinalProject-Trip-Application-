import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/model/airport.dart';
import 'package:travel_app/model/booking.dart';
import 'package:travel_app/view/My_page/tiket_page.dart';

class FlightsBookingList extends ConsumerWidget {
  const FlightsBookingList({super.key});

  // 예약 가져오기
  Future<List<Booking>> fetchBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection("booking")
        .where("uEmail", isEqualTo: user.email)
        .where("what", isEqualTo: "항공기")
        .get();

    return snapshot.docs
        .map((doc) => Booking.fromMap(doc.data(), doc.id))
        .where((b) => b.bState != "취소됨")
        .toList();
  }

  // 항공편 데이터 가져오기
  Future<Map<String, Airport?>> fetchAirplaneData(String aid) async {
    final startDoc =
        await FirebaseFirestore.instance.collection("airplane_start").doc(aid).get();
    final endDoc =
        await FirebaseFirestore.instance.collection("airplane_end").doc(aid).get();

    Airport? startAirport;
    Airport? endAirport;

    if (startDoc.exists) {
      startAirport = Airport.fromMap(startDoc.data()!, startDoc.id);
    }
    if (endDoc.exists) {
      endAirport = Airport.fromMap(endDoc.data()!, endDoc.id);
    }

    return {"start": startAirport, "end": endAirport};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // ✅ 밝은 배경
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)), // 다크네이비
        title: const Text(
          "항공기 예약 내역",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Booking>>(
        future: fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("오류 발생: ${snapshot.error}",
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                "예약 내역이 없습니다.",
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return FutureBuilder<Map<String, Airport?>>(
                future: fetchAirplaneData(booking.aid),
                builder: (context, airplaneSnap) {
                  if (airplaneSnap.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard("항공편 불러오는 중...");
                  }
                  if (!airplaneSnap.hasData ||
                      (airplaneSnap.data?["start"] == null &&
                          airplaneSnap.data?["end"] == null)) {
                    return _buildErrorCard(
                        "항공편 정보를 찾을 수 없습니다.\n예약번호: ${booking.bid}");
                  }

                  final start = airplaneSnap.data?["start"];
                  final end = airplaneSnap.data?["end"];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketPage(booking: booking),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // ✅ 카드 화이트
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 예약번호
                          Text(
                            "예약번호: ${booking.bid}",
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 출발/도착 정보
                          Row(
                            children: [
                              const Icon(Icons.flight_takeoff,
                                  color: Color(0xFF2563EB), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "출발: ${start?.start ?? end?.end} "
                                  "(${start?.date ?? end?.date} ${start?.time ?? end?.time})",
                                  style: const TextStyle(
                                      color: Color(0xFF1E293B), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.flight_land,
                                  color: Color(0xFF16A34A), size: 18), // 초록 강조
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "도착: ${end?.end ?? start?.end} "
                                  "(${end?.qDate ?? start?.qDate} ${end?.qTime ?? start?.qTime})",
                                  style: const TextStyle(
                                      color: Color(0xFF1E293B), fontSize: 13),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 항공사 & 기종
                          Row(
                            children: [
                              const Icon(Icons.airlines,
                                  color: Color(0xFFF59E0B), size: 18), // 주황 강조
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "항공사: ${start?.company ?? end?.company ?? '정보 없음'}"
                                  " · 기종: ${start?.fNum ?? end?.fNum ?? ''}",
                                  style: const TextStyle(
                                    color: Color(0xFF475569), // 보조 텍스트
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 예약 상태
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: booking.bState == "확정"
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              booking.bState,
                              style: TextStyle(
                                color: booking.bState == "확정"
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
