import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_app/vm/home_provider.dart';

class FlightSearch extends ConsumerStatefulWidget {
  const FlightSearch({super.key});

  @override
  ConsumerState<FlightSearch> createState() => _FlightSearchState();
}

class _FlightSearchState extends ConsumerState<FlightSearch> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final departureDate = ref.watch(departureDateProvider);
    final returnDate = ref.watch(returnDateProvider);
    final selectedStart = ref.watch(selectedStartProvider);
    final selectedEnd = ref.watch(selectedEndProvider);
    final travelers = ref.watch(travelersProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          GestureDetector(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Flight Search",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF667EEA),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isExpanded ? 1.0 : 0.0,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  
                  // 날짜 선택
                  GestureDetector(
                    onTap: () => _pickDateRange(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.date_range, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Travel Dates",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                (departureDate != null && returnDate != null)
                                    ? "$departureDate ~ $returnDate"
                                    : "Select dates",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: (departureDate != null && returnDate != null)
                                      ? const Color(0xFF2D3748)
                                      : const Color(0xFFA0AEC0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 출발지
                  ref.watch(uniqueStartProvider).when(
                    data: (starts) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedStart,
                        decoration: InputDecoration(
                          labelText: "From",
                          labelStyle: const TextStyle(color: Color(0xFF718096)),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 16),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                          ),
                        ),
                        items: starts.map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(code.length > 25 ? '${code.substring(0, 25)}...' : code),
                        )).toList(),
                        onChanged: (v) => ref.read(selectedStartProvider.notifier).state = v,
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA))),
                    error: (e, _) => Text("Error: $e"),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 목적지
                  ref.watch(uniqueEndProvider).when(
                    data: (ends) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedEnd,
                        decoration: InputDecoration(
                          labelText: "To",
                          labelStyle: const TextStyle(color: Color(0xFF718096)),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.flight_land, color: Colors.white, size: 16),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                          ),
                        ),
                        items: ends.map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(code.length > 25 ? '${code.substring(0, 25)}...' : code),
                        )).toList(),
                        onChanged: (v) => ref.read(selectedEndProvider.notifier).state = v,
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA))),
                    error: (e, _) => Text("Error: $e"),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 인원 선택
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Passengers",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2D3748),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (travelers > 1) {
                                    ref.read(travelersProvider.notifier).state--;
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: (travelers > 1)
                                        ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)])
                                        : null,
                                    color: (travelers > 1) ? null : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: (travelers > 1) ? Colors.white : const Color(0xFF718096),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  travelers.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ref.read(travelersProvider.notifier).state++,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 검색 버튼
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => ref.read(searchStateProvider.notifier).state = true,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Search Flights",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 3)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667EEA),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3748),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final start = DateFormat('yyyy-MM-dd').format(picked.start);
      final end = DateFormat('yyyy-MM-dd').format(picked.end);
      
      ref.read(departureDateProvider.notifier).state = start;
      ref.read(returnDateProvider.notifier).state = end;
    }
  }
}