import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/view/My_page/inquery_write_page.dart';
import 'package:travel_app/vm/inquery_provider.dart';

class InqueryListPage extends ConsumerWidget {
  const InqueryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inqueries = ref.watch(inqueryProvider);
    final filter = ref.watch(inqueryFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("문의 내역")),
      body: Column(
        children: [
          // ✅ 필터 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: [
                filter == InqueryFilter.all,
                filter == InqueryFilter.unanswered,
                filter == InqueryFilter.answered,
              ],
              onPressed: (index) {
                if (index == 0) {
                  ref.read(inqueryFilterProvider.notifier).state = InqueryFilter.all;
                } else if (index == 1) {
                  ref.read(inqueryFilterProvider.notifier).state = InqueryFilter.unanswered;
                } else {
                  ref.read(inqueryFilterProvider.notifier).state = InqueryFilter.answered;
                }
              },
              borderRadius: BorderRadius.circular(10),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("전체"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("미답변"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("답변완료"),
                ),
              ],
            ),
          ),

          // ✅ 리스트
          Expanded(
            child: inqueries.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text("문의 내역이 없습니다."));
                }

                // ✅ 필터 적용
                final filteredList = list.where((inq) {
                  if (filter == InqueryFilter.unanswered) {
                    return inq.reply == null || inq.reply!.isEmpty;
                  } else if (filter == InqueryFilter.answered) {
                    return inq.reply != null && inq.reply!.isNotEmpty;
                  }
                  return true; // 전체
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text("해당 조건의 문의가 없습니다."));
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final inq = filteredList[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text(
                          "[${inq.state}] ${inq.title}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text("내용: ${inq.content}"),
                            const SizedBox(height: 6),
                            Text("작성일: ${inq.date}"),
                          ],
                        ),
                        children: [
                          if (inq.reply != null && inq.reply!.isNotEmpty) ...[
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              child: Text(
                                "관리자 답변",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 12),
                              child: Text(inq.reply!),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                "답변 대기중...",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("오류: $e")),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const InqueryWritePage()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
