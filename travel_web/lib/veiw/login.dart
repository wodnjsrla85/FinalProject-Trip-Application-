import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_web/veiw/firest_page.dart';
import 'package:travel_web/veiw/register.dart';

final db = FirebaseFirestore.instance;

class LoginPage extends StatefulWidget {
 const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false; // UI용

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 241, 245, 249), // 밝은 그레이 배경
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 헤더
                Text(
                  '관리자 페이지',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '환영합니다! 계정에 로그인하세요.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 50),
                // 카드
                Card(
                  elevation: 8,
                  color: Colors.white, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 이메일
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('이메일 주소',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _id,
                            decoration: InputDecoration(
                              hintText: 'ID',
                              prefixIcon: Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty) ? '이메일을 입력하세요.' : null,
                          ),
                          SizedBox(height: 16),

                          // 비밀번호
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('비밀번호',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _pw,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: 'PW',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력하세요.' : null,
                          ),

                          SizedBox(height: 12),

                          // 옵션 행
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              Text('로그인 정보 저장'),
                              Spacer(),
                            ],
                          ),
                          SizedBox(height: 8),

                          // 로그인 버튼 (보라)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                elevation: 0,
                              ),
                              onPressed: login,
                              child: Text('로그인'),
                            ),
                          ),

                          SizedBox(height: 18),

                          // 구분선 “또는”
                          Row(
                            children: [
                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('또는', style: TextStyle(color: Colors.grey.shade600)),
                              ),
                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),

                          SizedBox(height: 12),

                          // 회원가입 링크
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('계정이 없으신가요?', style: TextStyle(color: Colors.grey.shade700)),
                              TextButton(
                                onPressed: () => Get.to(() => RegisterPage()),
                                child: Text('회원가입'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === 기존 로그인 로직 그대로 유지 ===
  Future<void> login() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    try {
      final id = _id.text.trim();
      final pw = _pw.text.trim();

      final doc = await db.collection('managers').doc(id).get();

      if (!doc.exists) {
        Get.snackbar('아이디 오류', '존재하지 않는 아이디입니다.');
        return;
      }

      final data = doc.data();
      final savedPw = data?['password'] as String?;
      if (savedPw == null) {
        Get.snackbar('데이터 오류', '비밀번호 정보가 없습니다.');
        return;
      }

      if (savedPw != pw) {
        Get.snackbar('비밀번호 오류', '비밀번호를 확인하세요.');
        return;
      }

      Get.to(() => FirestPage(), arguments: {'managerEmail': id});
    } catch (e) {
      Get.snackbar('오류 발생', e.toString());
    }
  }
}