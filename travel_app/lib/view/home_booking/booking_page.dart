import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/model/airport.dart';
import 'package:travel_app/model/booking.dart';

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

class _BookingPageState extends ConsumerState<BookingPage> with TickerProviderStateMixin {
  String? selectedClass;
  Set<String> selectedSeats = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, List<String>> generateSeats(int totalSeats) {
    final firstCount = (totalSeats * 0.1).round();
    final businessCount = (totalSeats * 0.2).round();
    final premiumCount = (totalSeats * 0.2).round();
    final economyCount = totalSeats - (firstCount + businessCount + premiumCount);

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
    final seatLayout = selectedClass != null ? seatLayouts[selectedClass] ?? <String>[] : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "${flight.start} → ${flight.end}",
          style: const TextStyle(
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF667EEA),
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 항공편 정보 카드
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.flight,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${flight.company} - ${flight.name}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Flight Information",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _flightInfoRow("Departure", "${flight.date} ${flight.time}", Icons.flight_takeoff),
                          const SizedBox(height: 12),
                          _flightInfoRow("Arrival", "${flight.qDate} ${flight.qTime}", Icons.flight_land),
                          const SizedBox(height: 12),
                          _flightInfoRow("Duration", flight.qDuration, Icons.schedule),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _flightInfoRow("Total Seats", "${flight.tSit}", Icons.airline_seat_recline_normal),
                              ),
                              Expanded(
                                child: _flightInfoRow("Passengers", "${widget.passengerCount}", Icons.people),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 좌석 클래스 선택
              const Text(
                "Select Class",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _classOption("first", "First Class", flight.fPrice, Icons.flight_class, const Color(0xFFFFD700)),
                    _classOption("business", "Business", flight.bPrice, Icons.business_center, const Color(0xFF667EEA)),
                    _classOption("premium", "Premium Economy", flight.pfPrice, Icons.star, const Color(0xFF48BB78)),
                    _classOption("economy", "Economy", flight.ePrice, Icons.event_seat, const Color(0xFF718096)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 좌석 선택
              if (selectedClass != null) ...[
                Row(
                  children: [
                    const Text(
                      "Select Seats",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedClass!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 좌석 범례
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _seatLegend("Selected", const Color(0xFF667EEA), Icons.event_seat),
                      _seatLegend("Available", const Color(0xFFE2E8F0), Icons.event_seat_outlined),
                      _seatLegend("Occupied", const Color(0xFFE53E3E), Icons.block),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // 항공기 좌석 배치
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 항공기 앞부분
                      Container(
                        width: 60,
                        height: 30,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: const Icon(
                          Icons.flight,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 좌석 그리드 (실제 항공기 배치처럼)
                      _buildSeatGrid(seatLayout),

                      const SizedBox(height: 16),
                      
                      // 항공기 뒷부분
                      Container(
                        width: 80,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 선택 정보
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF7FAFC), Color(0xFFEDF2F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF667EEA).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Booking Summary",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Selected Seats:"),
                          Text(
                            selectedSeats.isEmpty ? "None" : selectedSeats.join(", "),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Class:"),
                          Text(
                            selectedClass!.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (selectedSeats.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Price:"),
                            Text(
                              "₩${_getTotalPrice().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF667EEA),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: selectedClass != null && selectedSeats.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: selectedSeats.length == widget.passengerCount
                        ? const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          )
                        : null,
                    color: selectedSeats.length == widget.passengerCount 
                        ? null 
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: selectedSeats.length == widget.passengerCount
                        ? [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.4),
                              spreadRadius: 0,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: (selectedClass == null || selectedSeats.length != widget.passengerCount)
                        ? null
                        : () async {
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                throw Exception("로그인 필요");
                              }

                              int pricePerSeat = 0;
                              switch (selectedClass) {
                                case "economy":
                                  pricePerSeat = flight.ePrice;
                                  break;
                                case "business":
                                  pricePerSeat = flight.bPrice;
                                  break;
                                case "first":
                                  pricePerSeat = flight.fPrice;
                                  break;
                                case "premium":
                                  pricePerSeat = flight.pfPrice;
                                  break;
                              }

                              final totalPrice = pricePerSeat * selectedSeats.length;
                              final bookingRef = FirebaseFirestore.instance.collection('booking');
                              final docRef = bookingRef.doc();

                              final booking = Booking(
                                aid: flight.name,
                                uEmail: user.email ?? "unknown",
                                aPrice: totalPrice,
                                bDate: DateTime.now().toIso8601String(),
                                bSit: List<String>.from(selectedSeats),
                                bid: docRef.id,
                                bState: "결제완료",
                              );

                              await docRef.set(booking.toMap());

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Booking completed successfully!"),
                                  backgroundColor: Color(0xFF48BB78),
                                ),
                              );

                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Booking failed: $e"),
                                  backgroundColor: const Color(0xFFE53E3E),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment,
                          color: selectedSeats.length == widget.passengerCount 
                              ? Colors.white 
                              : const Color(0xFF718096),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedSeats.length == widget.passengerCount 
                              ? "Book Now (${selectedSeats.length}/${widget.passengerCount})" 
                              : "Select ${widget.passengerCount - selectedSeats.length} more seats",
                          style: TextStyle(
                            color: selectedSeats.length == widget.passengerCount 
                                ? Colors.white 
                                : const Color(0xFF718096),
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

  Widget _flightInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _classOption(String classType, String className, int price, IconData icon, Color color) {
    final isSelected = selectedClass == classType;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedClass = classType;
          selectedSeats.clear();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    "₩${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? color : const Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _seatLegend(String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatGrid(List<String> seats) {
    // 실제 항공기처럼 6열 배치 (A B C  |복도|  D E F)
    final rows = (seats.length / 6).ceil();
    
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 왼쪽 좌석 (A, B, C)
              ...List.generate(3, (colIndex) {
                final seatIndex = rowIndex * 6 + colIndex;
                if (seatIndex >= seats.length) return const SizedBox(width: 40);
                return _buildSeat(seats[seatIndex]);
              }),
              
              // 복도
              const SizedBox(width: 32),
              Container(
                width: 2,
                height: 40,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 32),
              
              // 오른쪽 좌석 (D, E, F)
              ...List.generate(3, (colIndex) {
                final seatIndex = rowIndex * 6 + colIndex + 3;
                if (seatIndex >= seats.length) return const SizedBox(width: 40);
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
    final isOccupied = seat.hashCode % 7 == 0; // 임시로 일부 좌석을 점유된 것으로 표시
    
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
                        content: Text("Maximum ${widget.passengerCount} seats can be selected."),
                        backgroundColor: const Color(0xFFED8936),
                      ),
                    );
                  }
                }
              });
            },
      child: Container(
        margin: const EdgeInsets.all(2),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isOccupied
              ? const Color(0xFFE53E3E)
              : isSelected
                  ? const Color(0xFF667EEA)
                  : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isOccupied
              ? const Icon(Icons.close, color: Colors.white, size: 16)
              : isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      seat,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
        ),
      ),
    );
  }

  int _getTotalPrice() {
    int pricePerSeat = 0;
    switch (selectedClass) {
      case "economy":
        pricePerSeat = widget.flight.ePrice;
        break;
      case "business":
        pricePerSeat = widget.flight.bPrice;
        break;
      case "first":
        pricePerSeat = widget.flight.fPrice;
        break;
      case "premium":
        pricePerSeat = widget.flight.pfPrice;
        break;
    }
    return pricePerSeat * selectedSeats.length;
  }
}