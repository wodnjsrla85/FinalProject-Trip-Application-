import 'package:cloud_firestore/cloud_firestore.dart';

/// 기존 네이밍을 유지합니다: Admin
class Admin {
  /// 문서 ID == 이메일 (CEmail)
  final String email;

  /// 비밀번호 (CPw) - 운영 환경에서는 해시/또는 Firebase Auth 권장
  final String password;

  /// 직원 이름 (CName)
  final String? name;

  /// 직원 전화번호 (CPhone)
  final String? phone;

  /// 직급 (CType) e.g. 사원/대리/과장/Admin...
  final String? type;

  /// 입사일자 (CDate, date-only로 사용)
  final DateTime? joinDate;

  /// 생성시각(서버 타임스탬프)
  final DateTime? createdAt;

  const Admin({
    required this.email,
    required this.password,
    this.name,
    this.phone,
    this.type,
    this.joinDate,
    this.createdAt,
  });

  /// Firestore 문서 스냅샷에서 모델 생성 (doc.id를 이메일로 간주)
  factory Admin.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Admin(
      email: doc.id,
      password: (data['password'] ?? '') as String,
      name: data['CName'] as String?,
      phone: data['CPhone'] as String?,
      type: data['CType'] as String?,
      joinDate: _tsToDate(data['CDate']),
      createdAt: _tsToDate(data['createdAt']),
    );
  }

  /// Map만 있을 때 (기존 시그니처 호환)
  factory Admin.fromMap(String email, Map<String, dynamic> map) {
    return Admin(
      email: email,
      password: (map['password'] ?? '') as String,
      name: map['CName'] as String?,
      phone: map['CPhone'] as String?,
      type: map['CType'] as String?,
      joinDate: _tsToDate(map['CDate']),
      createdAt: _tsToDate(map['createdAt']),
    );
  }

  /// Firestore 저장용 Map
  Map<String, dynamic> toMap() => {
        'password': password, // 운영: 해시 또는 Firebase Auth 사용 권장
        'CName': name,
        'CPhone': phone,
        'CType': type,
        'CDate': joinDate == null ? null : Timestamp.fromDate(_dateOnly(joinDate!)),
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  Admin copyWith({
    String? email,
    String? password,
    String? name,
    String? phone,
    String? type,
    DateTime? joinDate,
    DateTime? createdAt,
  }) {
    return Admin(
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      joinDate: joinDate ?? this.joinDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ── helpers
  static DateTime? _tsToDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  /// CDate는 날짜만 쓰므로 시간을 00:00으로 정규화
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}