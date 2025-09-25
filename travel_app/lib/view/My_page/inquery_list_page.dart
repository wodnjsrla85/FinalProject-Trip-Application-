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
      backgroundColor: const Color(0xFFF8FAFC), // ✅ 밝은 배경
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)), // ✅ 다크네이비 아이콘
        elevation: 0,
        title: const Text(
          "문의 내역",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B), // ✅ 메인 텍스트
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // ✅ 필터 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ToggleButtons(
              isSelected: [
                filter == InqueryFilter.all,
                filter == InqueryFilter.unanswered,
                filter == InqueryFilter.answered,
              ],
              onPressed: (index) {
                if (index == 0) {
                  ref.read(inqueryFilterProvider.notifier).state =
                      InqueryFilter.all;
                } else if (index == 1) {
                  ref.read(inqueryFilterProvider.notifier).state =
                      InqueryFilter.unanswered;
                } else {
                  ref.read(inqueryFilterProvider.notifier).state =
                      InqueryFilter.answered;
                }
              },
              color: const Color(0xFF64748B), // ✅ 비선택 텍스트 그레이
              selectedColor: Colors.black,
              fillColor: const Color(0xFFFFD700), // ✅ 블루 포인트
              borderRadius: BorderRadius.circular(12),
              borderColor: Colors.black.withOpacity(0.1),
              selectedBorderColor: const Color(0xFFFFD700),
              constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
              children: const [
                Text("전체"),
                Text("미답변"),
                Text("답변완료"),
              ],
            ),
          ),

          // ✅ 리스트
          Expanded(
            child: inqueries.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      "문의 내역이 없습니다.",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }

                // ✅ 필터 적용
                final filteredList = list.where((inq) {
                  if (filter == InqueryFilter.unanswered) {
                    return inq.reply == null || inq.reply!.isEmpty;
                  } else if (filter == InqueryFilter.answered) {
                    return inq.reply != null && inq.reply!.isNotEmpty;
                  }
                  return true;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text(
                      "해당 조건의 문의가 없습니다.",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final inq = filteredList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white, // ✅ 카드 화이트
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.08), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        iconColor: const Color(0xFF2563EB),
                        collapsedIconColor: const Color(0xFF94A3B8),
                        childrenPadding: const EdgeInsets.all(16),
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(
                          "[${inq.state}] ${inq.title}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B), // ✅ 메인 텍스트
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inq.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B), // ✅ 보조 텍스트
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "작성일: ${inq.date}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8), // ✅ 더 옅은 보조
                                ),
                              ),
                            ],
                          ),
                        ),
                        children: [
                          if (inq.reply != null && inq.reply!.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9), // ✅ 연한 블루그레이
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "관리자 답변",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB), // ✅ 블루 포인트
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    inq.reply!,
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                "답변 대기중...",
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
              error: (e, _) => Center(
                child: Text(
                  "오류: $e",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),

      // ✅ 플로팅 버튼 (밝은 스타일)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFD700), // ✅ 옐로우 포인트
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InqueryWritePage()),
          );
        },
        child: const Icon(Icons.add, color: Color(0xFF1E293B)), // ✅ 다크네이비 아이콘
      ),
    );
  }
}
