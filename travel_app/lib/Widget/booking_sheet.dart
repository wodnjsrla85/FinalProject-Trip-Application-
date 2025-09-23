import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class BookingSheet extends StatefulWidget {
  final int passengerCount;
  const BookingSheet({super.key, required this.passengerCount});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  late List<TextEditingController> passportControllers;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // ✅ 맥북 로컬 IP로 교체해야 함 (ifconfig로 확인)
  final String serverUrl = "http://192.168.20.7:8000";

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

  Future<void> _uploadPassportAndExtract(File imageFile, int index) async {
    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$serverUrl/extract-passport-info/"),
      );
      request.files.add(await http.MultipartFile.fromPath("image", imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        setState(() {
          passportControllers[index].text = data["passport_number"] ?? "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Passport number extracted")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ OCR 실패: $responseBody")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ 네트워크 오류: $e")),
      );
    }
  }

  Future<void> _pickPassportImage(int index) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      File imageFile = File(picked.path);
      _uploadPassportAndExtract(imageFile, index);
    }
  }

  Future<void> _makePayment() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.post(
        Uri.parse("$serverUrl/create-payment-intent/"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "amount": 5000,
          "currency": "usd",
        }),
      );

      final data = json.decode(response.body);
      final clientSecret = data['clientSecret'] ?? data['client_secret'];

      if (clientSecret == null) {
        throw Exception("❌ PaymentIntent 생성 실패: ${data['error']}");
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Travel App',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Payment Successful!")),
      );

      final passports = passportControllers.map((c) => c.text).toList();
      Navigator.pop(context, {"passports": passports, "payment": "card"});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Payment failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Passenger Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              for (int i = 0; i < widget.passengerCount; i++) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passportControllers[i],
                        decoration: InputDecoration(
                          labelText: "Passenger ${i + 1} Passport Number",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Color(0xFF667EEA)),
                      onPressed: () => _pickPassportImage(i),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (passportControllers.any((c) => c.text.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("⚠️ 여권 번호를 입력하거나 추출하세요.")),
                          );
                          return;
                        }
                        _makePayment();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.credit_card, color: Colors.white),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Pay with Credit Card",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
