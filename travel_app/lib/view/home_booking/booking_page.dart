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
  Set<String> occupiedSeats = {};

  final bookingProvider = BookingProvider();

  @override
  void initState() {
    super.initState();
    _loadOccupiedSeats();
  }

  Future<void> _loadOccupiedSeats() async {
    final seats = await bookingProvider.getOccupiedSeats(widget.flight.id);
    setState(() {
      occupiedSeats = seats;
    });
  }

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
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  leading: Padding(
    padding: const EdgeInsets.all(8),
    child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
      ),
    ),
  ),
  title: Column(
    children: [
      Text(
        "${flight.start} → ${flight.end}",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
      Text(
        flight.company,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
      ),
    ],
  ),
  centerTitle: true,
  actions: [
    FutureBuilder<bool>(
      future: SaveProvider().isFlightSaved(flight.id),
      builder: (context, snapshot) {
        final isSaved = snapshot.data ?? false;
        return Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () async {
              try {
                await SaveProvider().toggleFlight(flight.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isSaved ? "저장 해제되었습니다." : "저장되었습니다!"),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("실패: $e"),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.amber : Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      },
    ),
  ],
),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20,),
            // Hero Flight Card
            Container(
              margin: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Airline Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.flight, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${flight.company} - ${flight.name}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "Flight Details",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Flight Route
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flight.time,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              flight.start,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              flight.date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              flight.qDuration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 60,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF475569),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(Icons.flight, color: Color(0xFF475569), size: 16),
                        ],
                      ),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              flight.qTime,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              flight.end,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              flight.qDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Flight Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoChip("${flight.tSit} Seats", Icons.airline_seat_recline_normal),
                      _buildInfoChip("${widget.passengerCount} Passengers", Icons.person),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Selection
                  const Text(
                    "Select Class",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildClassCard("first", "First Class", flight.fPrice, const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  _buildClassCard("business", "Business Class", flight.bPrice, const Color(0xFF3B82F6)),
                  const SizedBox(height: 12),
                  _buildClassCard("premium", "Premium Economy", flight.pfPrice, const Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  _buildClassCard("economy", "Economy Class", flight.ePrice, const Color(0xFF6B7280)),
                  
                  const SizedBox(height: 32),
                  
                  // Seat Selection
                  if (selectedClass != null) ...[
                    Row(
                      children: [
                        const Text(
                          "Select Seats",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            selectedClass!.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Seat Legend
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLegendItem("Selected", const Color(0xFF3B82F6)),
                          _buildLegendItem("Available", const Color(0xFF374151)),
                          _buildLegendItem("Occupied", const Color(0xFFEF4444)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Aircraft Layout
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Aircraft Front
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF334155),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flight, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Aircraft Front",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: _buildSeatGrid(seatLayout),
                          ),
                          
                          // Aircraft Rear
                          Container(
                            width: 60,
                            height: 15,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF374151),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Booking Summary
                    if (selectedSeats.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt_long, color: Colors.black, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Booking Summary",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow("Selected Seats", selectedSeats.join(", ")),
                            _buildSummaryRow("Class", selectedClass!.toUpperCase()),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Price",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "₩${_getTotalPrice().toString().replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (Match m) => '${m[1]},')}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                  
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBar: selectedClass != null && selectedSeats.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: SafeArea(
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: selectedSeats.length == widget.passengerCount
                        ? () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BookingSheet(
                                passengerCount: widget.passengerCount,
                                price: _getPricePerSeat(),
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
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text("예약이 완료되었습니다!"),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );

                                _loadOccupiedSeats();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text("예약 실패: $e"),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedSeats.length == widget.passengerCount
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF374151),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedSeats.length == widget.passengerCount
                              ? Icons.flight_takeoff
                              : Icons.event_seat,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedSeats.length == widget.passengerCount
                              ? "Book Now (${selectedSeats.length}/${widget.passengerCount})"
                              : "Select ${widget.passengerCount - selectedSeats.length} more seats",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(String classType, String className, int price, Color accentColor) {
    final isSelected = selectedClass == classType;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accentColor : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedClass = classType;
              selectedSeats.clear();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.airline_seat_recline_normal, color: accentColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₩${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: accentColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatGrid(List<String> seats) {
    final rows = (seats.length / 6).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(3, (colIndex) {
                final seatIndex = rowIndex * 6 + colIndex;
                if (seatIndex >= seats.length) return const SizedBox(width: 32);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildSeat(seats[seatIndex]),
                );
              }),
              const SizedBox(width: 24),
              ...List.generate(3, (colIndex) {
                final seatIndex = rowIndex * 6 + colIndex + 3;
                if (seatIndex >= seats.length) return const SizedBox(width: 32);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildSeat(seats[seatIndex]),
                );
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
                        content: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.white),
                            const SizedBox(width: 8),
                            Text("Maximum ${widget.passengerCount} seats can be selected."),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 32,
        decoration: BoxDecoration(
          color: isOccupied
              ? const Color(0xFFEF4444)
              : isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF374151),
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: const Color(0xFF60A5FA), width: 2) : null,
        ),
        child: Center(
          child: isOccupied
              ? const Icon(Icons.close, color: Colors.white, size: 12)
              : isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : Text(
                      seat,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

