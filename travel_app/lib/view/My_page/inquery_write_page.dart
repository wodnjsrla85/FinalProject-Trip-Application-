import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/inquery_provider.dart';
import 'package:travel_app/model/airport.dart';
import 'package:travel_app/model/travel_package.dart';
import 'package:travel_app/vm/pacakge_provider.dart';

final inqueryRefIdProvider = StateProvider<String>((ref) => ""); // 선택된 문서 ID 저장

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
    final to = ref.read(inqueryToProvider); // 문의 대상
    final refId = ref.read(inqueryRefIdProvider); // 선택한 패키지/항공편 ID

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
        "refId": refId, // 패키지/항공편 ID 저장
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
      appBar: AppBar(title: const Text("문의하기")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 문의 대상 선택
            DropdownButtonFormField<String>(
              value: selectedTo,
              items: const [
                DropdownMenuItem(value: "어플", child: Text("어플")),
                DropdownMenuItem(value: "항공사", child: Text("항공사")),
                DropdownMenuItem(value: "여행사", child: Text("여행사")),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(inqueryToProvider.notifier).state = value;
                  ref.read(inqueryRefIdProvider.notifier).state = ""; // 선택 초기화
                }
              },
              decoration: const InputDecoration(
                labelText: "문의 대상",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 여행사 → 패키지 드롭다운
            if (selectedTo == "여행사")
              ref.watch(packageProvider).when(
                data: (packages) => DropdownButtonFormField<String>(
                  value: refId.isNotEmpty ? refId : null,
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
                  decoration: const InputDecoration(
                    labelText: "패키지 선택",
                    border: OutlineInputBorder(),
                  ),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("패키지 불러오기 실패: $e"),
              ),

  // 항공사 → 항공편 드롭다운 (FutureBuilder, start + end 합치기)
if (selectedTo == "항공사")
  FutureBuilder<List<QuerySnapshot>>(
    future: Future.wait([
      FirebaseFirestore.instance.collection("airplane_start").get(),
      FirebaseFirestore.instance.collection("airplane_end").get(),
    ]),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }
      if (snapshot.hasError) {
        return Text("항공편 불러오기 실패: ${snapshot.error}");
      }
      if (!snapshot.hasData) {
        return const Text("항공편 데이터 없음");
      }

      // 두 컬렉션 결과 합치기
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
        decoration: const InputDecoration(
          labelText: "항공편 선택",
          border: OutlineInputBorder(),
        ),
      );
    },
  ),


            const SizedBox(height: 16),

            // 제목 입력
            TextField(
              onChanged: (v) =>
                  ref.read(inqueryTitleProvider.notifier).state = v,
              decoration: const InputDecoration(
                labelText: "제목",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 내용 입력
            Expanded(
              child: TextField(
                onChanged: (v) =>
                    ref.read(inqueryContentProvider.notifier).state = v,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: "내용",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 등록 버튼
            SizedBox(
              width: double.infinity,
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
                    : const Icon(Icons.send),
                label: Text(isLoading ? "저장중..." : "등록하기"),
                onPressed:
                    isLoading ? null : () => _submitInquery(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
