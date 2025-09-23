import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/model/airport.dart';
import 'package:travel_app/model/booking.dart';
import 'package:travel_app/view/My_page/tiket_page.dart';

class FlightsBookingList extends ConsumerWidget {
  const FlightsBookingList({super.key});

  // 예약 가져오기 (Firestore에서 전체 가져온 후 클라이언트에서 "취소됨" 제거)
  Future<List<Booking>> fetchBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection("booking")
        .where("uEmail", isEqualTo: user.email)
        .where("what", isEqualTo: "항공기")
        .get();

    // 클라이언트에서 "취소됨" 상태 제거
    return snapshot.docs
        .map((doc) => Booking.fromMap(doc.data(), doc.id))
        .where((b) => b.bState != "취소됨") // 여기서 필터링
        .toList();
  }

  // 항공편 데이터 가져오기
  Future<Map<String, Airport?>> fetchAirplaneData(String aid) async {
    final startDoc = await FirebaseFirestore.instance
        .collection("airplane_start")
        .doc(aid)
        .get();

    final endDoc = await FirebaseFirestore.instance
        .collection("airplane_end")
        .doc(aid)
        .get();

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
      appBar: AppBar(title: const Text("항공기 예약 내역")),
      body: FutureBuilder<List<Booking>>(
        future: fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("오류 발생: ${snapshot.error}"));
          }
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text("예약 내역이 없습니다."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return FutureBuilder<Map<String, Airport?>>(
                future: fetchAirplaneData(booking.aid),
                builder: (context, airplaneSnap) {
                  if (airplaneSnap.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(
                      title: Text("항공편 불러오는 중..."),
                      leading: CircularProgressIndicator(),
                    );
                  }
                  if (!airplaneSnap.hasData ||
                      (airplaneSnap.data?["start"] == null &&
                          airplaneSnap.data?["end"] == null)) {
                    return ListTile(
                      title: const Text("항공편 정보 없음"),
                      subtitle: Text("예약번호: ${booking.bid}"),
                    );
                  }

                  final start = airplaneSnap.data?["start"];
                  final end = airplaneSnap.data?["end"];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text("예약번호: ${booking.bid}"),
                      subtitle: Text(
                        "✈️ 출발: ${start?.start ?? end?.end} "
                        "(${start?.date ?? end?.date} ${start?.time ?? end?.time})\n"
                        "➡️ 도착: ${end?.end ?? start?.end} "
                        "(${end?.date ?? start?.qDate} ${end?.time ?? start?.qTime})\n"
                        "항공사: ${start?.company ?? end?.company ?? '정보 없음'}, "
                        "기종: ${start?.fNum ?? end?.fNum ?? ''}\n"
                        "상태: ${booking.bState}", // 예약 상태 표시
                      ),
                      trailing: Text(
                        booking.what ?? "",
                        style: const TextStyle(fontSize: 12),
                      ),

                      // 티켓 페이지 연결
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketPage(booking: booking),
                          ),
                        );
                      },
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
}
