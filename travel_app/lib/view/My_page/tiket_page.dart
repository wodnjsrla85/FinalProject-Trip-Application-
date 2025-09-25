import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:travel_app/model/booking.dart';
import 'package:travel_app/vm/booking_provider.dart';

class TicketPage extends StatelessWidget {
  final Booking booking;
  const TicketPage({super.key, required this.booking});

  void _cancelBooking(BuildContext context) async {
    final provider = BookingProvider();

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
                  child: const Icon(
                    Icons.warning_outlined,
                    color: Colors.red,
                    size: 32,
                  ),
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
                const Text(
                  "정말 이 예약을 취소하시겠습니까?\n취소된 예약은 복구할 수 없습니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF475569),
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
                          foregroundColor: const Color(0xFF1E293B),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("아니요"),
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
                        child: const Text(
                          "예",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
      await provider.cancelBooking(booking.bid);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("예약이 취소되었습니다."),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // ✅ 밝은 배경
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1E293B), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "My Ticket",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: Color(0xFF1E293B), size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 120),
            // Main Ticket Card
            Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTicketHeader(),
                  _buildTicketDivider(),
                  _buildTicketBody(),
                ],
              ),
            ),
            _buildQRSection(),
            _buildBookingDetails(),
            _buildActionButtons(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Booking ID
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Booking #${booking.bid.substring(0, 8).toUpperCase()}",
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Status Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: booking.bState == "예약완료"
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  booking.bState == "예약완료"
                      ? Icons.check_circle
                      : Icons.schedule,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.bState,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDivider() {
    return Divider(
      thickness: 1,
      color: Colors.grey.shade300,
      indent: 24,
      endIndent: 24,
    );
  }

  Widget _buildTicketBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Price Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount",
                  style: TextStyle(
                      color: Color(0xFF64748B), fontSize: 14)),
              Text(
                "₩${booking.aPrice.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},')}",
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Payment Method
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Payment Method",
                  style: TextStyle(
                      color: Color(0xFF64748B), fontSize: 14)),
              Chip(
                backgroundColor: const Color(0xFFE2E8F0),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.credit_card,
                        color: Color(0xFF1E293B), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      booking.payment ?? '카드',
                      style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Text("Scan for Check-in",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          QrImageView(
            data: booking.bid,
            version: QrVersions.auto,
            size: 180.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 20),
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: booking.bid,
            width: 200,
            height: 60,
            drawText: false,
            color: const Color(0xFF1E293B),
          ),
          const SizedBox(height: 12),
          Text(
            booking.bid.substring(0, 12).toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Booking Details",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          if (booking.bSit.isNotEmpty) ...[
            const Text("Seats",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: booking.bSit.map((seat) {
                return Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.airline_seat_recline_normal,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(seat,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  backgroundColor: const Color(0xFF003366),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          const Text("Passengers",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ...booking.passports.asMap().entries.map((entry) {
            int index = entry.key;
            String passport = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF003366),
                    child: Text("${index + 1}",
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text("Passport Number",
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF94A3B8))),
                        Text(passport,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B))),
                      ]))
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.withOpacity(0.5)),
            foregroundColor: Colors.red,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _cancelBooking(context),
          label: const Text("Cancel Booking",
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.support_agent, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {},
          label: const Text("Contact Support",
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
