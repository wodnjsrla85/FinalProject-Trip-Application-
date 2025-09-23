// lib/ui/widgets/booking_panel_by_class.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingPanelByClass extends StatefulWidget {
  final String flightDocId;
  const BookingPanelByClass({super.key, required this.flightDocId});

  @override
  State<BookingPanelByClass> createState() => _BookingPanelByClassState();
}

class _BookingPanelByClassState extends State<BookingPanelByClass> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String seatClassOf(String seatCode) {
    if (seatCode.isEmpty) return '기타';
    final c = seatCode[0].toUpperCase();
    switch (c) {
      case 'F':
        return '퍼스트';
      case 'B':
        return '비즈니스';
      case 'P':
        return '프리미엄이코노미';
      case 'E':
        return '이코노미';
      default:
        return '기타';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 + 검색
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '예매 현황(좌석 등급별)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _q,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                      hintText: '이메일 검색',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 데이터
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('booking')
                  .where('aid', isEqualTo: widget.flightDocId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('예매 내역이 없습니다.'),
                  );
                }

                final queryText = _q.text.trim().toLowerCase();

                // 등급별 집계 구조
                final Map<String, int> seatCount = {
                  '퍼스트': 0,
                  '비즈니스': 0,
                  '프리미엄이코노미': 0,
                  '이코노미': 0,
                  '기타': 0,
                };
                final Map<String, Map<String, List<String>>> details = {
                  // cls → { email → [좌석들] }
                  '퍼스트': {},
                  '비즈니스': {},
                  '프리미엄이코노미': {},
                  '이코노미': {},
                  '기타': {},
                };

                for (final d in snap.data!.docs) {
                  final m = d.data();
                  final email = (m['uEmail'] ?? '').toString();
                  if (queryText.isNotEmpty &&
                      !email.toLowerCase().contains(queryText)) {
                    continue; // 검색 필터
                  }
                  final seats =
                      (m['bSit'] as List?)?.cast<String>() ?? const <String>[];
                  for (final s in seats) {
                    final cls = seatClassOf(s);
                    seatCount[cls] = (seatCount[cls] ?? 0) + 1;
                    details[cls]!.putIfAbsent(email, () => []).add(s);
                  }
                }

                // 표시 순서
                const order = ['퍼스트', '비즈니스', '프리미엄이코노미', '이코노미', '기타'];

                return Column(
                  children: order.map((cls) {
                    final nSeats = seatCount[cls] ?? 0;
                    final emailMap = details[cls]!;
                    if (nSeats == 0 && emailMap.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      title: Row(
                        children: [
                          Text(cls,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('좌석 $nSeats'),
                          const SizedBox(width: 8),
                          Text('(예약자 ${emailMap.keys.length}명)'),
                        ],
                      ),
                      children: emailMap.entries.map((entry) {
                        final email = entry.key;
                        final seats = entry.value..sort();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(email,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: -4,
                                  children: seats
                                      .map((s) => Chip(
                                            label: Text(s),
                                            visualDensity: VisualDensity.compact,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}