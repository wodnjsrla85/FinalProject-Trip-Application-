import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/view/home_booking/booking_page.dart';
import 'package:travel_app/vm/home_provider.dart';

class FlightResult extends ConsumerStatefulWidget {
  const FlightResult({super.key});

  @override
  ConsumerState<FlightResult> createState() => _FlightResultState();
}

class _FlightResultState extends ConsumerState<FlightResult> {
  bool isExpanded = true; // ✅ 접힘/펼침 상태

  @override
  Widget build(BuildContext context) {
    final searchDataAsync = ref.watch(flightsProvider);

    return searchDataAsync.when(
      data: (flights) {
        if (flights.isEmpty) {
          return _buildEmptyState();
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (클릭하면 접힘/펼침)
              GestureDetector(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: Row(
                  children: [
                    const Text(
                      "Available Flights",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF003366), // 네이비 블루
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF003366),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${flights.length}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF003366)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 접힘/펼침 영역
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: flights.length,
                  itemBuilder: (context, index) {
                    final flight = flights[index];
                    return _buildFlightCard(context, flight);
                  },
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoading(),
      error: (err, _) => _buildError(err),
    );
  }

  /// ✈️ 항공편 카드 UI
  Widget _buildFlightCard(BuildContext context, dynamic flight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 항공편 정보
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF003366),
                child: const Icon(Icons.flight, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${flight.start} → ${flight.end}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF003366), // 네이비 블루
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Direct Flight",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (flight.ePrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Best Price",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 날짜 + 가격
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF003366)),
              const SizedBox(width: 8),
              Text(
                flight.date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003366),
                ),
              ),
              const Spacer(),
              if (flight.ePrice != null)
                Text(
                  "₩${flight.ePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 예약 버튼
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingPage(
                      flight: flight,
                      passengerCount: ref.watch(travelersProvider),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), // 옐로우 버튼
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Book Now",
                style: TextStyle(
                  color: Color(0xFF003366), // 블루 텍스트
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🛑 검색 결과 없음
  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.flight_takeoff, size: 40, color: Color(0xFF94A3B8)),
            ),
            SizedBox(height: 16),
            Text(
              "No flights found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF003366),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Try adjusting your search criteria",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );

  /// ⏳ 로딩 상태
  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF003366), strokeWidth: 2.5),
            SizedBox(height: 16),
            Text(
              "Searching for flights...",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );

  /// ❌ 에러 상태
  Widget _buildError(Object err) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE11D48)),
            const SizedBox(height: 16),
            const Text(
              "Something went wrong",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Error: $err",
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
