import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/inquery_provider.dart';
import 'package:travel_app/model/airport.dart';
import 'package:travel_app/vm/pacakge_provider.dart';

final inqueryRefIdProvider = StateProvider<String>((ref) => "");

class InqueryWritePage extends ConsumerWidget {
  const InqueryWritePage({super.key});

  Future<void> _submitInquery(BuildContext context, WidgetRef ref) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인이 필요합니다.")),
      );
      return;
    }

    final title = ref.read(inqueryTitleProvider);
    final content = ref.read(inqueryContentProvider);
    final to = ref.read(inqueryToProvider);
    final refId = ref.read(inqueryRefIdProvider);

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("제목과 내용을 입력하세요.")),
      );
      return;
    }

    if ((to == "여행사" || to == "항공사") && refId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("문의할 대상을 선택하세요.")),
      );
      return;
    }

    ref.read(inqueryLoadingProvider.notifier).state = true;

    try {
      await FirebaseFirestore.instance.collection("inquery").add({
        "uEmail": userEmail,
        "aEmail": "admin@test.com",
        "date": DateTime.now().toIso8601String(),
        "state": "대기중",
        "title": title,
        "content": content,
        "to": to,
        "refId": refId,
      });

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("문의가 등록되었습니다.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 실패: $e")),
      );
    } finally {
      ref.read(inqueryLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(inqueryLoadingProvider);
    final selectedTo = ref.watch(inqueryToProvider);
    final refId = ref.watch(inqueryRefIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // ✅ 밝은 배경
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)), // ✅ 다크네이비
        title: const Text(
          "문의하기",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 문의 대상 선택
            _buildInputCard(
              child: DropdownButtonFormField<String>(
                value: selectedTo,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF1E293B)),
                items: const [
                  DropdownMenuItem(value: "어플", child: Text("어플")),
                  DropdownMenuItem(value: "항공사", child: Text("항공사")),
                  DropdownMenuItem(value: "여행사", child: Text("여행사")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(inqueryToProvider.notifier).state = value;
                    ref.read(inqueryRefIdProvider.notifier).state = "";
                  }
                },
                decoration: _inputDecoration("문의 대상"),
              ),
            ),
            const SizedBox(height: 16),

            // 여행사 → 패키지 선택
            if (selectedTo == "여행사")
              _buildInputCard(
                child: ref.watch(packageProvider).when(
                      data: (packages) => DropdownButtonFormField<String>(
                        value: refId.isNotEmpty ? refId : null,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Color(0xFF1E293B)),
                        items: packages
                            .map((pkg) => DropdownMenuItem(
                                  value: pkg.id,
                                  child: Text("${pkg.pName} (${pkg.pStart}~${pkg.pEnd})"),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(inqueryRefIdProvider.notifier).state = value;
                          }
                        },
                        decoration: _inputDecoration("패키지 선택"),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                      ),
                      error: (e, _) => Text("패키지 불러오기 실패: $e",
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
              ),

            // 항공사 → 항공편 선택
            if (selectedTo == "항공사")
              _buildInputCard(
                child: FutureBuilder<List<QuerySnapshot>>(
                  future: Future.wait([
                    FirebaseFirestore.instance.collection("airplane_start").get(),
                    FirebaseFirestore.instance.collection("airplane_end").get(),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(color: Color(0xFF2563EB));
                    }
                    if (snapshot.hasError) {
                      return Text("항공편 불러오기 실패: ${snapshot.error}",
                          style: const TextStyle(color: Colors.redAccent));
                    }
                    if (!snapshot.hasData) {
                      return const Text("항공편 데이터 없음",
                          style: TextStyle(color: Color(0xFF64748B)));
                    }

                    final allDocs = [
                      ...snapshot.data![0].docs,
                      ...snapshot.data![1].docs,
                    ];

                    final flights = allDocs
                        .map((doc) =>
                            Airport.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                        .toList();

                    return DropdownButtonFormField<String>(
                      value: refId.isNotEmpty ? refId : null,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF1E293B)),
                      items: flights
                          .map((f) => DropdownMenuItem(
                                value: f.id,
                                child: Text("${f.company} ${f.name} (${f.start}→${f.end})"),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(inqueryRefIdProvider.notifier).state = value;
                        }
                      },
                      decoration: _inputDecoration("항공편 선택"),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // 제목 입력
            _buildInputCard(
              child: TextField(
                style: const TextStyle(color: Color(0xFF1E293B)),
                onChanged: (v) => ref.read(inqueryTitleProvider.notifier).state = v,
                decoration: _inputDecoration("제목"),
              ),
            ),
            const SizedBox(height: 16),

            // 내용 입력
            SizedBox(
              height: 340,
              child: _buildInputCard(
                child: TextField(
                  style: const TextStyle(color: Color(0xFF1E293B)),
                  onChanged: (v) => ref.read(inqueryContentProvider.notifier).state = v,
                  maxLines: null,
                  expands: true,
                  decoration: _inputDecoration("내용").copyWith(
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(
                  isLoading ? "저장중..." : "등록하기",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700), // ✅ 블루 포인트
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: isLoading ? null : () => _submitInquery(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 공통 인풋 카드
  Widget _buildInputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ 카드 화이트
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  // 공통 InputDecoration
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B)), // ✅ 보조 텍스트
      border: InputBorder.none,
    );
  }
}
