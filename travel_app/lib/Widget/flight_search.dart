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
  @override
  Widget build(BuildContext context) {
    final departureDate = ref.watch(departureDateProvider);
    final selectedStart = ref.watch(selectedStartProvider);
    final selectedEnd = ref.watch(selectedEndProvider);
    final travelers = ref.watch(travelersProvider);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF003366).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: const [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF003366),
                child: Icon(Icons.flight_takeoff, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Securely Book\nyour Flight Ticket",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF003366),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 출발지
          ref.watch(uniqueStartProvider).when(
                data: (starts) => _buildDropdown(
                  label: "From",
                  value: selectedStart,
                  items: starts,
                  icon: Icons.flight_takeoff,
                  onChanged: (v) =>
                      ref.read(selectedStartProvider.notifier).state = v,
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("Error: $e"),
              ),
          const SizedBox(height: 16),

          // 목적지
          ref.watch(uniqueEndProvider).when(
                data: (ends) => _buildDropdown(
                  label: "To",
                  value: selectedEnd,
                  items: ends,
                  icon: Icons.flight_land,
                  onChanged: (v) =>
                      ref.read(selectedEndProvider.notifier).state = v,
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("Error: $e"),
              ),
          const SizedBox(height: 16),

          // 출발 날짜
          _buildDateField("Departure", departureDate ?? "Select Date", () {
            _pickDateRange(context, ref);
          }),
          const SizedBox(height: 16),

          // 인원 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Travelers",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF003366),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildTravelerButton(Icons.remove, () {
                    if (travelers > 1) {
                      ref.read(travelersProvider.notifier).state--;
                    }
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      travelers.toString().padLeft(2, "0"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ),
                  _buildTravelerButton(Icons.add, () {
                    ref.read(travelersProvider.notifier).state++;
                  }),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 검색 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  ref.read(searchStateProvider.notifier).state = true,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), // 옐로우
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Search",
                style: TextStyle(
                  color: Color(0xFF003366), // 블루 텍스트
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 공통 Dropdown UI
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: Color(0xFF003366)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      items: items
          .map((code) => DropdownMenuItem(
                value: code,
                child: Text(
                  code.length > 25 ? '${code.substring(0, 25)}...' : code,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  // 공통 Date UI
  Widget _buildDateField(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 18, color: Color(0xFF003366)),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: value.contains("Select")
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF003366),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Traveler 버튼
  Widget _buildTravelerButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Color(0xFF003366)),
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
    );

    if (picked != null) {
      final start = DateFormat('yyyy-MM-dd').format(picked.start);
      final end = DateFormat('yyyy-MM-dd').format(picked.end);

      ref.read(departureDateProvider.notifier).state = start;
      ref.read(returnDateProvider.notifier).state = end;
    }
  }
}
