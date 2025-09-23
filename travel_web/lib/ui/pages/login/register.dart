import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_web/models/admin.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final db = FirebaseFirestore.instance;

  // Controllers
  final _name  = TextEditingController(); // CName
  final _id    = TextEditingController(); // CEmail
  final _pw    = TextEditingController(); // CPw
  final _pw2   = TextEditingController(); // CPw 확인
  final _phone = TextEditingController(); // CPhone
  // 1) 항공사 리스트 (중복 제거)
final List<String> _airlines = <String>{
  '에티하드 항공', '일본항공', '중화항공', '아시아나항공', '에어캐나다', '진에어',
  '웨스트젯', '말레이시아 항공', '타이항공', '델타항공', '전일본공수',
  '대한항공', '싱가포르항공', '샤먼항공', '이얏호항공사', '재원항공사',
}.toList();

// 2) 상태값 (기존과 동일하게 사용)
  String _type = '대한항공'; // 초기 선택값 예시

  // UI States
  bool _obscure1 = true;
  bool _obscure2 = true;
  DateTime? _joinDate;                  // CDate

  // Email duplicate check
  Timer? _debounce;
  bool _checkingId = false;
  bool _idAvailable = false;
  String? _idError;

  @override
  void initState() {
    super.initState();
    _name.addListener(_rebuild);
    _id.addListener(_rebuild);
    _pw.addListener(_rebuild);
    _pw2.addListener(_rebuild);
    _phone.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.removeListener(_rebuild);
    _id.removeListener(_rebuild);
    _pw.removeListener(_rebuild);
    _pw2.removeListener(_rebuild);
    _phone.removeListener(_rebuild);
    _name.dispose();
    _id.dispose();
    _pw.dispose();
    _pw2.dispose();
    _phone.dispose();
    super.dispose();
  }

  // ── Email(아이디) 중복 검사 with debounce
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
        final snap = await db.collection('admin').doc(id).get();
        final exists = snap.exists;
        setState(() {
          _checkingId = false;
          _idAvailable = !exists;
          _idError = exists ? '이미 사용 중인 이메일(아이디)입니다.' : null;
        });
        _formKey.currentState?.validate();
      } catch (_) {
        setState(() {
          _checkingId = false;
          _idAvailable = false;
          _idError = '아이디 확인 중 오류가 발생했습니다.';
        });
        _formKey.currentState?.validate();
      }
    });
  }

  // ── 저장: 모델 기반
  Future<bool> _saveManagerWithModel(Admin m) async {
    try {
      final id = m.email.trim().toLowerCase();
      final docRef = db.collection('admin').doc(id);

      // 서버측 최종 중복 방지
      if ((await docRef.get()).exists) {
        Get.snackbar('중복 아이디', '이미 사용 중인 이메일(아이디)입니다.');
        return false;
      }

      await docRef.set(m.toMap());
      return true;
    } catch (e) {
      Get.snackbar('오류 발생', e.toString());
      return false;
    }
  }

  // ── 날짜 선택
  Future<void> _pickJoinDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 30, 1, 1);
    final last  = DateTime(now.year + 1, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? now,
      firstDate: first,
      lastDate: last,
      helpText: '입사일자 선택 (CDate)',
    );
    if (picked != null) setState(() => _joinDate = picked);
  }

  // ── 정규식 유틸
  bool _isEmail(String v) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(v);
  bool _isPhone(String v) =>
      RegExp(r'^[0-9\-+() ]{8,}$').hasMatch(v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
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
                SizedBox(height: 24),

                Card(
                  color: Colors.white,
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
                          // CName
                          _label(theme, '이름'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _name,
                            decoration: _inputDeco(
                              hint: '이름을 입력하세요',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return '이름을 입력하세요.';
                              if (v.trim().length < 2) return '이름은 2자 이상이어야 합니다.';
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: 16),

                          // CEmail
                          _label(theme, '이메일(아이디)'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _id,
                            decoration: _inputDeco(
                              hint: '이메일을 입력하세요',
                              icon: Icons.alternate_email,
                              suffix: _checkingId
                                  ? Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : (_id.text.trim().isEmpty
                                      ? null
                                      : (_idError == null
                                          ? Icon(Icons.check_circle, size: 20, color: Color(0xFF22C55E))
                                          : Icon(Icons.error_outline, size: 20, color: Color(0xFFEF4444)))),
                              helper: (_id.text.trim().isEmpty) ? null : (_idError ?? '사용 가능한 아이디입니다.'),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: _onIdChanged,
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return '이메일을 입력하세요.';
                              if (!_isEmail(t)) return '올바른 이메일 형식이 아닙니다.';
                              if (_idError != null) return _idError;
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: 16),

                          // CPw
                          _label(theme, '비밀번호 '),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _pw,
                            obscureText: _obscure1,
                            decoration: _inputDeco(
                              hint: '비밀번호를 입력하세요 (4자 이상)',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return '비밀번호를 입력하세요.';
                              if (v.length < 4) return '비밀번호는 4자 이상이어야 합니다.';
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: 16),

                          // CPw 확인
                          _label(theme, '비밀번호 확인'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _pw2,
                            obscureText: _obscure2,
                            decoration: _inputDeco(
                              hint: '비밀번호를 다시 입력하세요',
                              icon: Icons.lock_person,
                              suffix: IconButton(
                                icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return '비밀번호 확인을 입력하세요.';
                              if (v != _pw.text) return '비밀번호가 일치하지 않습니다.';
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: 16),

                          // CPhone
                          _label(theme, '전화번호 '),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDeco(
                              hint: '예) 010-1234-5678',
                              icon: Icons.phone_iphone,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return '전화번호를 입력하세요.';
                              if (!_isPhone(v.trim())) return '전화번호 형식이 올바르지 않습니다.';
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: 16),

                          // CType
                        _label(theme, '항공사 검색'),
                          const SizedBox(height: 8),
                          Autocomplete<String>(
                            // 초기 표시값을 현재 선택값과 동기화
                            initialValue: TextEditingValue(text: _type),
                            // 필터링 로직: 입력이 비었으면 전체, 아니면 포함 검색
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              final q = textEditingValue.text.trim();
                              if (q.isEmpty) return _airlines;
                              return _airlines.where(
                                (a) => a.toLowerCase().contains(q.toLowerCase()),
                              );
                            },
                            onSelected: (String selection) {
                              setState(() => _type = selection);
                            },
                            // 검색 입력창을 기존 데코레이션으로 래핑
                            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                              // 외부 상태값 변화 시에도 입력창 텍스트를 맞춰줌
                              if (textController.text != _type) {
                                textController.text = _type;
                                textController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: textController.text.length),
                                );
                              }
                              return TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                decoration: _inputDeco(icon: Icons.flight, hint: '항공사 검색'),
                                onFieldSubmitted: (_) => onFieldSubmitted(),
                                validator: (v) {
                                  // 필요 시: 목록 외 값 방지
                                  if (v == null || !_airlines.contains(v)) {
                                    return '목록에서 항공사를 선택해 주세요.';
                                  }
                                  return null;
                                },
                                onSaved: (v) => _type = v ?? _type,
                              );
                            },
                            // 옵션 목록 UI(선택): 기본 리스트보다 더 예쁘게 커스터마이즈
                            optionsViewBuilder: (context, onSelected, options) {
                              final opts = options.toList();
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 260, minWidth: 280),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: opts.length,
                                      itemBuilder: (context, index) {
                                        final String airline = opts[index];
                                        return ListTile(
                                          dense: true,
                                          title: Text(airline),
                                          onTap: () => onSelected(airline),
                                          leading: const Icon(Icons.flight_takeoff),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // CDate
                          _label(theme, '입사일자 (CDate)'),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: _pickJoinDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: _inputDeco(icon: Icons.event, hint: '입사일자를 선택하세요'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _joinDate == null
                                        ? '미선택'
                                        : '${_joinDate!.year}-${_joinDate!.month.toString().padLeft(2, '0')}-${_joinDate!.day.toString().padLeft(2, '0')}',
                                  ),
                                  Icon(Icons.calendar_month),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Submit
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
                                      final m = Admin(
                                        email: _id.text.trim(),
                                        password: _pw.text,       // 운영: 해시 또는 Firebase Auth 권장
                                        name: _name.text.trim(),
                                        phone: _phone.text.trim(),
                                        type: _type,
                                        joinDate: _joinDate,
                                        createdAt: null,          // serverTimestamp 사용
                                      );

                                      final ok = await _saveManagerWithModel(m);
                                      if (ok) {
                                        Get.back();
                                        Get.snackbar('회원가입 완료', '축하드립니다.');
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
                          SizedBox(height: 100),
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

  // ── UI helpers
  Widget _label(ThemeData theme, String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  InputDecoration _inputDeco({
    required IconData icon,
    String? hint,
    Widget? suffix,
    String? helper,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
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
    );
  }
}