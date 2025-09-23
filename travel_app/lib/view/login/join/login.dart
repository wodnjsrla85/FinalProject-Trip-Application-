import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/main_tab_screen.dart';
import 'package:travel_app/view/login/join/join.dart';

class Login extends ConsumerWidget {
  const Login({super.key});

  // 비밀번호 찾기 바텀시트
  void _showForgotPasswordBottomSheet(BuildContext context) {
    final emailController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF1C1C28),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 핸들바
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Color(0xFF404040),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: 32),

                        // 타이틀
                        Text(
                          "비밀번호 재설정",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "등록된 이메일로 재설정 링크를 보내드립니다",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9CA3AF),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 32),

                        // 이메일 입력 필드
                        Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFF404040),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "이메일 주소를 입력하세요",
                              hintStyle: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // 전송 버튼
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      if (emailController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text("이메일 주소를 입력해주세요"),
                                            backgroundColor: Color(0xFFEF4444),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        isLoading = true;
                                      });

                                      try {
                                        await FirebaseAuth.instance
                                            .sendPasswordResetEmail(
                                              email:
                                                  emailController.text.trim(),
                                            );

                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "비밀번호 재설정 이메일이 발송되었습니다!",
                                            ),
                                            backgroundColor: Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        String message;
                                        switch (e.code) {
                                          case 'user-not-found':
                                            message = "등록되지 않은 이메일입니다";
                                            break;
                                          case 'invalid-email':
                                            message = "올바른 이메일 주소를 입력해주세요";
                                            break;
                                          default:
                                            message = "재설정 이메일 발송에 실패했습니다";
                                        }

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(message),
                                            backgroundColor: Color(0xFFEF4444),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      } finally {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child:
                                isLoading
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      "재설정 링크 발송",
                                      style: TextStyle(
                                        color: Color(0xFF1C1C28),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // 취소 버튼
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "취소",
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final pwController = TextEditingController();

    // Login 함수
    Future<void> login() async {
      try {
        final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: pwController.text.trim(),
        );

        final user = result.user;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainTabScreen()),
        );
      } on FirebaseAuthException catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("아이디 또는 비밀번호를 확인해주세요"),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFF1C1C28),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(height: 30),

                // 상단 로고 및 비행기 이미지
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A3A),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Stack(
                    children: [
                      // 비행기 아이콘
                      Center(
                        child: Transform.rotate(
                          angle: -0.7,
                          child: Icon(
                            Icons.airplanemode_active,
                            size: 60,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // 앱 타이틀
                Text(
                  "Sky Travel",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "항공여행의 새로운 시작",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: 48),

                // 로그인 폼
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF404040), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 웰컴 메시지
                      Text(
                        "로그인",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF404040),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "계정에 로그인하여 여행을 시작하세요",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),

                      // 이메일 입력 필드
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF404040),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Color(0xFF404040), // 커서 색상 지정
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                          decoration: InputDecoration(
                            hintText: "이메일 주소",
                            hintStyle: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // 비밀번호 입력 필드
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF404040),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: pwController,
                          obscureText: true,
                          cursorColor: Color(0xFF404040), // 커서 색상 지정
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                          decoration: InputDecoration(
                            hintText: "비밀번호",
                            hintStyle: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // 로그인 버튼
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Color(0xFF1C1C28),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // 공백 확인
                            if (emailController.text.trim().isEmpty ||
                                pwController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("모든 필드를 입력해주세요"),
                                  backgroundColor: Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } else {
                              // 로그인 함수 실행
                              login();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "로그인",
                            style: TextStyle(
                              color: Colors.white,
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

                // 하단 링크들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        _showForgotPasswordBottomSheet(context);
                      },
                      child: Text(
                        "비밀번호 찾기",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Join()),
                        );
                      },
                      child: Text(
                        "회원가입",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                Spacer(),

                // 하단 카피라이트
                Padding(
                  padding: EdgeInsets.only(bottom: 34),
                  child: Text(
                    "© 2025 Sky Travel. 모든 권리 보유.",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
