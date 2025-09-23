import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/Widget/booking_sheet.dart';
import 'package:travel_app/model/airport.dart';
import 'package:travel_app/vm/booking_provider.dart';
import 'package:travel_app/vm/save_provider.dart';

class BookingPage extends ConsumerStatefulWidget {
  final Airport flight;
  final int passengerCount;

  const BookingPage({
    super.key,
    required this.flight,
    required this.passengerCount,
  });

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  String? selectedClass;
  Set<String> selectedSeats = {};
  Set<String> occupiedSeats = {}; // 예약된 좌석 목록

  final bookingProvider = BookingProvider();

  @override
  void initState() {
    super.initState();
    _loadOccupiedSeats();
  }

  /// 예약된 좌석 불러오기
  Future<void> _loadOccupiedSeats() async {
    final seats = await bookingProvider.getOccupiedSeats(widget.flight.id);
    setState(() {
      occupiedSeats = seats;
    });
  }

  /// 클래스별 좌석 자동 배치
  Map<String, List<String>> generateSeats(int totalSeats) {
    final firstCount = (totalSeats * 0.1).round();
    final businessCount = (totalSeats * 0.2).round();
    final premiumCount = (totalSeats * 0.2).round();
    final economyCount =
        totalSeats - (firstCount + businessCount + premiumCount);

    List<String> buildSeats(String prefix, int count) {
      return List.generate(count, (i) => "$prefix${i + 1}");
    }

    return {
      "first": buildSeats("F", firstCount),
      "business": buildSeats("B", businessCount),
      "premium": buildSeats("P", premiumCount),
      "economy": buildSeats("E", economyCount),
    };
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final seatLayouts = generateSeats(flight.tSit);
    final seatLayout =
        selectedClass != null ? seatLayouts[selectedClass] ?? <String>[] : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text("${flight.start} → ${flight.end}"),
        centerTitle: true,
        actions: [
          // 저장 버튼 (항공편 북마크)
          FutureBuilder<bool>(
            future: SaveProvider().isFlightSaved(flight.id),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.amber : Colors.white,
                ),
                onPressed: () async {
                  try {
                    await SaveProvider().toggleFlight(flight.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              isSaved ? "저장 해제되었습니다." : "저장되었습니다!")),
                    );
                    setState(() {}); // UI 갱신
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("실패: $e")),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 항공편 정보 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flight),
                        const SizedBox(width: 8),
                        Text(
                          "${flight.company} - ${flight.name}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _flightInfoRow("Departure", "${flight.date} ${flight.time}"),
                    _flightInfoRow("Arrival", "${flight.qDate} ${flight.qTime}"),
                    _flightInfoRow("Duration", flight.qDuration),
                    _flightInfoRow("Total Seats", "${flight.tSit}"),
                    _flightInfoRow("Passengers", "${widget.passengerCount}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 좌석 클래스 선택
            const Text("Select Class",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _classOption("first", "First Class", flight.fPrice, Colors.amber),
            _classOption("business", "Business", flight.bPrice, Colors.blue),
            _classOption("premium", "Premium Economy", flight.pfPrice, Colors.green),
            _classOption("economy", "Economy", flight.ePrice, Colors.grey),

            const SizedBox(height: 20),

            // 좌석 선택
            if (selectedClass != null) ...[
              Row(
                children: [
                  Text("Select Seats",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Chip(label: Text(selectedClass!.toUpperCase())),
                ],
              ),
              const SizedBox(height: 12),

              // 좌석 범례
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _seatLegend("Selected", Colors.blue),
                  _seatLegend("Available", Colors.grey.shade300),
                  _seatLegend("Occupied", Colors.red),
                ],
              ),
              const SizedBox(height: 16),

              // 좌석 그리드
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: const Icon(Icons.flight,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(height: 16),
                      _buildSeatGrid(seatLayout),
                      const SizedBox(height: 16),
                      Container(
                        width: 60,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 예약 요약
              if (selectedSeats.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Booking Summary",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("Selected Seats: ${selectedSeats.join(", ")}"),
                        Text("Class: ${selectedClass!.toUpperCase()}"),
                        Text(
                          "Total Price: ₩${_getTotalPrice().toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},')}",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),

      // 예약 버튼
      bottomNavigationBar: selectedClass != null && selectedSeats.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => BookingSheet(
                      passengerCount: widget.passengerCount,
                    ),
                  );

                  if (result != null) {
                    try {
                      await bookingProvider.createBooking(
                        aid: widget.flight.id,
                        pricePerSeat: _getPricePerSeat(),
                        selectedSeats: selectedSeats.toList(),
                        flightDate: widget.flight.date,
                        passports: List<String>.from(result['passports']),
                        payment: result['payment'],
                        what: "항공기",
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("예약이 완료되었습니다!")),
                      );

                      _loadOccupiedSeats(); // 예약 후 좌석 갱신
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("예약 실패: $e")),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedSeats.length == widget.passengerCount
                      ? Colors.blue
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  selectedSeats.length == widget.passengerCount
                      ? "Book Now (${selectedSeats.length}/${widget.passengerCount})"
                      : "Select ${widget.passengerCount - selectedSeats.length} more seats",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            )
          : null,
    );
  }

  Widget _flightInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _classOption(String classType, String className, int price, Color color) {
    final isSelected = selectedClass == classType;

    return Card(
      color: isSelected ? color.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(Icons.airline_seat_recline_normal, color: color),
        title: Text(className),
        subtitle: Text(
            "₩${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"),
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
        onTap: () {
          setState(() {
            selectedClass = classType;
            selectedSeats.clear();
          });
        },
      ),
    );
  }

  Widget _seatLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSeatGrid(List<String> seats) {
    final rows = (seats.length / 6).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(3, (colIndex) {
                final seatIndex = rowIndex * 6 + colIndex;
                if (seatIndex >= seats.length) return const SizedBox(width: 30);
                return _buildSeat(seats[seatIndex]);
              }),
              const SizedBox(width: 20),
              ...List.generate(3, (colIndex) {
                final seatIndex = rowIndex * 6 + colIndex + 3;
                if (seatIndex >= seats.length) return const SizedBox(width: 30);
                return _buildSeat(seats[seatIndex]);
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSeat(String seat) {
    final isSelected = selectedSeats.contains(seat);
    final isOccupied = occupiedSeats.contains(seat);

    return GestureDetector(
      onTap: isOccupied
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seat);
                } else {
                  if (selectedSeats.length < widget.passengerCount) {
                    selectedSeats.add(seat);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Maximum ${widget.passengerCount} seats can be selected.")),
                    );
                  }
                }
              });
            },
      child: Container(
        margin: const EdgeInsets.all(1),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isOccupied
              ? Colors.red
              : isSelected
                  ? Colors.blue
                  : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: isOccupied
              ? const Icon(Icons.close, color: Colors.white, size: 12)
              : isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : Text(
                      seat,
                      style: const TextStyle(
                          fontSize: 8, fontWeight: FontWeight.bold),
                    ),
        ),
      ),
    );
  }

  int _getPricePerSeat() {
    switch (selectedClass) {
      case "economy":
        return widget.flight.ePrice;
      case "business":
        return widget.flight.bPrice;
      case "first":
        return widget.flight.fPrice;
      case "premium":
        return widget.flight.pfPrice;
      default:
        return 0;
    }
  }

  int _getTotalPrice() {
    return _getPricePerSeat() * selectedSeats.length;
  }
}
