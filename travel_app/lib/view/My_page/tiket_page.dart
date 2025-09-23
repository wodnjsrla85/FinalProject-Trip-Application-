import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:travel_app/model/booking.dart';
import 'package:travel_app/vm/booking_provider.dart'; // BookingProvider import

class TicketPage extends StatelessWidget {
  final Booking booking;
  const TicketPage({super.key, required this.booking});

  // 예약 취소 함수
  void _cancelBooking(BuildContext context) async {
    final provider = BookingProvider();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("예약 취소"),
          content: const Text("정말 이 예약을 취소하시겠습니까?"),
          actions: [
            TextButton(
              child: const Text("아니요"),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text("예"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await provider.cancelBooking(booking.bid);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("예약이 취소되었습니다.")),
        );
        Navigator.pop(context); // 취소 후 화면 닫기
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("탑승권")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView( // 스크롤 가능
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "예약번호: ${booking.bid}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // QR 코드
              Center(
                child: QrImageView(
                  data: booking.bid,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),

              // 바코드
              Center(
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: booking.bid,
                  width: 200,
                  height: 80,
                  drawText: false,
                ),
              ),
              const SizedBox(height: 40),

              // 예약 상세 정보
              const Text("예약 정보",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),

              Text("상태: ${booking.bState}"),
              Text("결제 수단: ${booking.payment ?? '정보 없음'}"),
              Text("총 결제 금액: ${booking.aPrice}원"),
              const SizedBox(height: 12),

              const Text("예약 좌석",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: booking.bSit
                    .map((seat) => Chip(
                          label: Text(seat),
                          backgroundColor: Colors.blue.shade100,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),

              const Text("탑승객 여권번호",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: booking.passports
                    .map((p) => Text("- $p"))
                    .toList(),
              ),

              const SizedBox(height: 40),

              // 예약 취소 버튼
              Center(
                child: ElevatedButton(
                  onPressed: () => _cancelBooking(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("예약 취소"),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("닫기"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
