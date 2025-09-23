import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/model/app_user.dart';
import 'package:travel_app/vm/user_provider.dart';

class Join extends ConsumerWidget {
  const Join({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 컨트롤러
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    // 성별 선택 값
    final sexList = ["남자", "여자"];
    String? selectedSex;

    Future<void> signUp() async {
      try {
        final auth = ref.read(firebaseAuthProvider);
        final db = ref.read(userProvider);

        // Authentication 등록
        final cred = await auth.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: pwCtrl.text.trim(),
        );

        // AppUser 생성
        final newUser = AppUser(
          uid: cred.user!.uid, // Authentication UI를 이용해 database에도 저장
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          sex: selectedSex ?? "남자",
          age: int.tryParse(ageCtrl.text.trim()) ?? 0,
          phone: phoneCtrl.text.trim(),
          address: addressCtrl.text.trim(),
          createdAt: DateTime.now(),
        );

        // Firestore 저장
        await db.createUser(newUser);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("회원가입 성공!")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("회원가입 실패: $e")),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "이름",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "이메일",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwCtrl,
                decoration: const InputDecoration(
                  labelText: "비밀번호",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              // 성별 선택
              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    value: selectedSex,
                    items: sexList
                        .map((sex) =>
                            DropdownMenuItem(value: sex, child: Text(sex)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedSex = val;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "성별",
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageCtrl,
                decoration: const InputDecoration(
                  labelText: "나이",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: "전화번호",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: "주소",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (emailCtrl.text.trim().isEmpty ||
                      pwCtrl.text.trim().isEmpty ||
                      nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("필수 입력값을 확인하세요")),
                    );
                  } else {
                    signUp();
                  }
                },
                child: const Text("회원가입"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
