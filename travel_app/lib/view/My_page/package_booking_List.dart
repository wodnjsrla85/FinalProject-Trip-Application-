import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/booking_provider.dart';

class PackageBookingList extends ConsumerWidget {
  const PackageBookingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("패키지 예약 내역"),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: BookingProvider().getMyPackageBookingsWithDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }

          final bookingsWithDetails = snapshot.data ?? [];

          if (bookingsWithDetails.isEmpty) {
            return const Center(child: Text('패키지 예약이 없습니다'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookingsWithDetails.length,
            itemBuilder: (context, index) {
              final item = bookingsWithDetails[index];
              final booking = item['booking']; // Booking 객체
              final packageInfo = item['package']; // Map<String, dynamic>?

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬
                    children: [
                      // 이미지 섹션
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child:
                              packageInfo != null &&
                                      packageInfo['images'] != null
                                  ? Image.network(
                                    packageInfo['images'][0],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      );
                                    },
                                  )
                                  : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 텍스트 섹션
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 패키지명
                            if (packageInfo != null) ...[
                              Text(
                                packageInfo['pName'] ?? '패키지명 없음',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // 여행 기간
                              Text(
                                '${packageInfo['pStart']} ~ ${packageInfo['pEnd']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // 예약 정보
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        booking.bState == '결제완료'
                                            ? Colors.green
                                            : Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    booking.bState ?? '상태 없음',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '인원수: ${booking.bSit?.isNotEmpty == true ? booking.bSit!.first : "1"}명',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // 가격 정보
                            Text(
                              '${booking.aPrice}원',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),

                            // 예약일
                            Text(
                              '예약일: ${booking.bDate}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
