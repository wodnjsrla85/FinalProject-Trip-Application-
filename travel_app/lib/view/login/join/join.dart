import 'package:firebase_auth/firebase_auth.dart';
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
    final sexList = ["Male", "Female"];
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

        // 이메일 인증 발송
        await cred.user!.sendEmailVerification();

        // AppUser 생성 (이메일 인증 상태 포함)
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

        // Firestore 저장
        await db.createUser(newUser);

        if (context.mounted) {
          // 이메일 인증 안내 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(
                email: emailCtrl.text.trim(),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sign up failed: $e"),
              backgroundColor: Color(0xFFE53E3E),
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
      required String label,
      required String hint,
      required IconData icon,
      TextInputType? keyboardType,
      bool obscureText = false,
    }) {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF667EEA).withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF2D3748),
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: TextStyle(
              color: Color(0xFF667EEA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Color(0xFFA0AEC0),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: Color(0xFF667EEA),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(0xFF667EEA),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A202C),
              Color(0xFF2D3748),
              Color(0xFF4A5568),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 헤더
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Join AirTravel today",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFA0AEC0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 메인 컨텐츠
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 25,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 입력 필드들
                        buildTextField(
                          controller: nameCtrl,
                          label: "Full Name",
                          hint: "Enter your full name",
                          icon: Icons.person_outline,
                        ),

                        buildTextField(
                          controller: emailCtrl,
                          label: "Email Address",
                          hint: "Enter your email",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        buildTextField(
                          controller: pwCtrl,
                          label: "Password",
                          hint: "Create a password",
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),

                        // 성별 선택
                        StatefulBuilder(
                          builder: (context, setState) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667EEA).withOpacity(0.08),
                                    spreadRadius: 0,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedSex,
                                items: sexList
                                    .map((sex) => DropdownMenuItem(
                                          value: sex,
                                          child: Text(
                                            sex,
                                            style: TextStyle(
                                              color: Color(0xFF2D3748),
                                              fontSize: 15,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedSex = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: "Gender",
                                  labelStyle: TextStyle(
                                    color: Color(0xFF667EEA),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.people_outline,
                                    color: Color(0xFF667EEA),
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFF667EEA),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF667EEA),
                                ),
                              ),
                            );
                          },
                        ),

                        buildTextField(
                          controller: ageCtrl,
                          label: "Age",
                          hint: "Enter your age",
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                        ),

                        buildTextField(
                          controller: phoneCtrl,
                          label: "Phone Number",
                          hint: "Enter your phone number",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        buildTextField(
                          controller: addressCtrl,
                          label: "Address",
                          hint: "Enter your address",
                          icon: Icons.location_on_outlined,
                        ),

                        SizedBox(height: 8),

                        // 회원가입 버튼
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF667EEA),
                                Color(0xFF764BA2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF667EEA).withOpacity(0.4),
                                spreadRadius: 0,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (emailCtrl.text.trim().isEmpty ||
                                  pwCtrl.text.trim().isEmpty ||
                                  nameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Please fill in all required fields"),
                                    backgroundColor: Color(0xFFE53E3E),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } else {
                                signUp();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // 이미 계정이 있는 경우
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                "Sign In",
                                style: TextStyle(
                                  color: Color(0xFF667EEA),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// 이메일 인증 대기 화면
class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isLoading = false;

  Future<void> resendVerification() async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Verification email sent!"),
            backgroundColor: Color(0xFF48BB78),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send email: $e"),
            backgroundColor: Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkVerification() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 사용자 정보 새로고침
      await FirebaseAuth.instance.currentUser!.reload();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user!.emailVerified) {
        // 인증 완료 - 로그인 화면으로 이동
        if (mounted) {
          // 회원가입부터 인증까지 모든 화면을 제거하고 로그인 화면으로
          Navigator.of(context).popUntil((route) => route.isFirst);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Email verified successfully! Please sign in."),
              backgroundColor: Color(0xFF48BB78),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        // 아직 인증되지 않음
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Email not verified yet. Please check your email."),
              backgroundColor: Color(0xFFED8936),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error checking verification: $e"),
            backgroundColor: Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A202C),
              Color(0xFF2D3748),
              Color(0xFF4A5568),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이메일 아이콘
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF667EEA).withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 32),

                // 메인 컨테이너
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 25,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Verify Your Email",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 16),
                      
                      Text(
                        "We've sent a verification email to:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 8),
                      
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667EEA),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 24),
                      
                      Text(
                        "Please check your email and click the verification link to activate your account.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 32),
                      
                      // 인증 확인 버튼
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667EEA).withOpacity(0.4),
                              spreadRadius: 0,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : checkVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "I've Verified My Email",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // 재발송 버튼
                      TextButton(
                        onPressed: isLoading ? null : resendVerification,
                        child: Text(
                          "Didn't receive email? Resend",
                          style: TextStyle(
                            color: Color(0xFF667EEA),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // 하단 텍스트
                Text(
                  "Check your spam folder if you don't see the email",
                  style: TextStyle(
                    color: Color(0xFFA0AEC0),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}