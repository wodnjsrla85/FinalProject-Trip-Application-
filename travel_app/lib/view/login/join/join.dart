import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/model/app_user.dart';
import 'package:travel_app/vm/user_provider.dart';

class Join extends ConsumerWidget {
  const Join({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final sexList = ["Male", "Female"];
    String? selectedSex;

    Future<void> signUp() async {
      try {
        final auth = ref.read(firebaseAuthProvider);
        final db = ref.read(userProvider);

        final cred = await auth.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: pwCtrl.text.trim(),
        );
        await cred.user!.sendEmailVerification();

        final newUser = AppUser(
          uid: cred.user!.uid,
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          sex: selectedSex ?? "Male",
          age: int.tryParse(ageCtrl.text.trim()) ?? 0,
          phone: phoneCtrl.text.trim(),
          address: addressCtrl.text.trim(),
          createdAt: DateTime.now(),
        );

        await db.createUser(newUser);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("회원가입 성공! 이메일 인증 후 로그인해주세요."),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("회원가입 실패: $e"),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }

    Widget buildTextField({
      required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool obscureText = false,
      TextInputType? keyboardType,
    }) {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFB0C4DE), width: 1),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          cursorColor: Color(0xFF003366), // 블루 커서
          style: TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            prefixIcon: Icon(icon, color: Color(0xFF6B7280), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF003366), // 네이비 블루
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: 32),

              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Sky Travel 회원가입",
                style: TextStyle(fontSize: 16, color: Color(0xFFB0C4DE)),
              ),

              SizedBox(height: 48),

              // 메인 카드
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF003366), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildTextField(
                      controller: nameCtrl,
                      hint: "Full Name",
                      icon: Icons.person_outline,
                    ),
                    buildTextField(
                      controller: emailCtrl,
                      hint: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    buildTextField(
                      controller: pwCtrl,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    buildTextField(
                      controller: ageCtrl,
                      hint: "Age",
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    buildTextField(
                      controller: phoneCtrl,
                      hint: "Phone Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    buildTextField(
                      controller: addressCtrl,
                      hint: "Address",
                      icon: Icons.location_on_outlined,
                    ),

                    // 성별 드롭다운
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFB0C4DE), width: 1),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedSex,
                        dropdownColor: Colors.white,
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                        onChanged: (val) => selectedSex = val,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.people_outline,
                            color: Color(0xFF6B7280),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: sexList.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // 회원가입 버튼
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD700), // 옐로우 버튼
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (emailCtrl.text.trim().isEmpty ||
                              pwCtrl.text.trim().isEmpty ||
                              nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("모든 필드를 입력해주세요"),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          } else {
                            signUp();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: Text(
                          "회원가입",
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
              ),

              SizedBox(height: 24),

              // 하단 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "이미 계정이 있나요? ",
                    style: TextStyle(color: Color(0xFFB0C4DE)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "로그인",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40),

              Padding(
                padding: EdgeInsets.only(bottom: 34),
                child: Text(
                  "© 2025 Sky Travel. 모든 권리 보유.",
                  style: TextStyle(color: Color(0xFFB0C4DE), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
