import 'package:flutter/material.dart';

class BookingSheet extends StatefulWidget {
  final int passengerCount;
  const BookingSheet({super.key, required this.passengerCount});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  late List<TextEditingController> passportControllers;
  String? paymentMethod;

  @override
  void initState() {
    super.initState();
    passportControllers = List.generate(
      widget.passengerCount,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var c in passportControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // 키보드 대응
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Passenger Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // 인원 수만큼 여권 번호 입력칸 생성
              for (int i = 0; i < widget.passengerCount; i++) ...[
                TextField(
                  controller: passportControllers[i],
                  decoration: InputDecoration(
                    labelText: "Passenger ${i + 1} Passport Number",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 결제 방식 선택
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(
                  labelText: "Payment Method",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "card", child: Text("Credit Card")),
                  DropdownMenuItem(value: "bank", child: Text("Bank Transfer")),
                  DropdownMenuItem(value: "paypal", child: Text("PayPal")),
                ],
                onChanged: (v) => setState(() => paymentMethod = v),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  if (passportControllers.any((c) => c.text.isEmpty) ||
                      paymentMethod == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("모든 정보를 입력하세요.")),
                    );
                    return;
                  }

                  final passports =
                      passportControllers.map((c) => c.text).toList();

                  Navigator.pop(context, {
                    "passports": passports,
                    "payment": paymentMethod,
                  });
                },
                child: const Text("Confirm Booking"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
