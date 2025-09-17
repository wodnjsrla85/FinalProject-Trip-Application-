import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  final db = FirebaseFirestore.instance;

  // 중복 검사 상태
  Timer? _debounce;
  bool _checkingId = false;
  bool _idAvailable = false;
  String? _idError;

  @override
  void dispose() {
    _debounce?.cancel();
    _id.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  // 아이디 중복 검사 (디바운스)
  void _onIdChanged(String raw) {
    _debounce?.cancel();
    final id = raw.trim().toLowerCase();

    if (id.isEmpty) {
      setState(() {
        _checkingId = false;
        _idAvailable = false;
        _idError = null;
      });
      return;
    }

    _debounce = Timer(Duration(milliseconds: 400), () async {
      setState(() {
        _checkingId = true;
        _idError = null;
      });
      try {
        final snap = await db.collection('managers').doc(id).get();
        final exists = snap.exists;
        setState(() {
          _checkingId = false;
          _idAvailable = !exists;
          _idError = exists ? '이미 사용 중인 아이디입니다.' : null;
        });
        _formKey.currentState?.validate();
      } catch (e) {
        setState(() {
          _checkingId = false;
          _idAvailable = false;
          _idError = '아이디 확인 중 오류가 발생했습니다.';
        });
        _formKey.currentState?.validate();
      }
    });
  }

  Future<bool> addmanagers(String email, String password) async {
    try {
      final id = email.trim().toLowerCase();
      final docRef = db.collection('managers').doc(id);

      // 서버측 최종 중복 방지
      final snap = await docRef.get();
      if (snap.exists) {
        Get.snackbar('중복 아이디', '이미 사용 중인 아이디입니다.');
        return false;
      }

      await docRef.set({
        'id': id,
        'password': password, // 데모용: 실서비스는 해시 권장
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      Get.snackbar('오류 발생', e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB), // 로그인과 동일 배경
      appBar: AppBar(
        backgroundColor: Color(0xFFF6F8FB),
        elevation: 0,
        title: Text(''),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '회원가입',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '아이디와 비밀번호를 입력해 계정을 생성하세요.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 24),

                // 카드
                Card(
                  color: Colors.white, // 로그인과 동일(화이트)
                  elevation: 8,
                  shadowColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 아이디
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('아이디',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _id,
                            decoration: InputDecoration(
                              hintText: 'ID를 입력하세요',
                              prefixIcon: Icon(Icons.person_add_outlined),
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
                              suffixIcon: _checkingId
                                  ? Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : (_id.text.trim().isEmpty
                                      ? null
                                      : (_idError == null
                                          ? Icon(Icons.check_circle, size: 20, color: Color(0xFF22C55E))
                                          : Icon(Icons.error_outline, size: 20, color: Color(0xFFEF4444)))),
                              helperText: (_id.text.trim().isEmpty) ? null : (_idError ?? '사용 가능한 아이디입니다.'),
                            ),
                            textInputAction: TextInputAction.next,
                            onChanged: _onIdChanged,
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return '아이디를 입력하세요.';
                              if (t.length < 3) return '아이디는 3자 이상이어야 합니다.';
                              if (_idError != null) return _idError;
                              return null;
                            },
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
                            obscureText: _obscure1,
                            decoration: InputDecoration(
                              hintText: 'PW를 입력하세요',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
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
                            validator: (v) {
                              if (v == null || v.isEmpty) return '비밀번호를 입력하세요.';
                              if (v.length < 4) return '비밀번호는 4자 이상이어야 합니다.';
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // 비밀번호 확인
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('비밀번호 확인',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _pw2,
                            obscureText: _obscure2,
                            decoration: InputDecoration(
                              hintText: 'PW를 다시 입력하세요',
                              prefixIcon: Icon(Icons.lock_person),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure2 = !_obscure2),
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
                            validator: (v) {
                              if (v == null || v.isEmpty) return '비밀번호 확인을 입력하세요.';
                              if (v != _pw.text) return '비밀번호가 일치하지 않습니다.';
                              return null;
                            },
                          ),

                          SizedBox(height: 20),

                          // 회원가입 버튼 (보라)
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
                              onPressed: (!(_formKey.currentState?.validate() ?? false) || !_idAvailable)
                                  ? null
                                  : () async {
                                      final ok = await addmanagers(_id.text, _pw.text);
                                      if (ok) {
                                        Get.snackbar('회원가입 완료', '축하드립니다.');
                                        Get.back();
                                      }
                                    },
                              child: Text('회원가입'),
                            ),
                          ),

                          SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('로그인으로 돌아가기'),
                          ),
                          SizedBox(height: 100,)
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
}