import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/booking_provider.dart';

class PackageBookingList extends ConsumerStatefulWidget {
  const PackageBookingList({super.key});

  @override
  ConsumerState<PackageBookingList> createState() => _PackageBookingListState();
}

class _PackageBookingListState extends ConsumerState<PackageBookingList> {
  late Future<List<Map<String, dynamic>>> _futureBookings;

  @override
  void initState() {
    super.initState();
    _futureBookings = BookingProvider().getMyPackageBookingsWithDetails();
  }

  void _refreshList() {
    setState(() {
      _futureBookings = BookingProvider().getMyPackageBookingsWithDetails();
    });
  }

  Future<void> _cancelBooking(String bookingId, String packageName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.warning_outlined,
                      color: Colors.red, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  "예약 취소",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "$packageName 예약을 취소하시겠습니까?\n취소된 예약은 복구할 수 없습니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("아니요",
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("예",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        await ref.read(bookingRepositoryProvider).cancelBooking(bookingId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("예약이 취소되었습니다."),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshList();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text("취소 실패: $e"),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // ✅ 밝은 배경
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Package Bookings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B), size: 20),
            onPressed: _refreshList,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureBookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text("오류 발생: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)),
              );
            }

            final bookingsWithDetails = snapshot.data ?? [];
            if (bookingsWithDetails.isEmpty) {
              return const Center(
                child: Text(
                  "No Package Bookings",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookingsWithDetails.length,
              itemBuilder: (context, index) {
                final item = bookingsWithDetails[index];
                final booking = item['booking'];
                final packageInfo = item['package'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 3,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 패키지명
                        Text(
                          packageInfo?['pName'] ?? '패키지명 없음',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 기간
                        Text(
                          '${packageInfo?['pStart']} ~ ${packageInfo?['pEnd']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 가격 & 예약일
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "₩${booking.aPrice}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            Text(
                              "Booked on ${booking.bDate}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 상태
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: booking.bState == '결제완료'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking.bState,
                            style: TextStyle(
                              color: booking.bState == '결제완료'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // 취소 버튼
                        if (booking.bState == '결제완료') ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _cancelBooking(
                              booking.bid,
                              packageInfo?['pName'] ?? '패키지',
                            ),
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.red),
                            label: const Text("Cancel Booking",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
