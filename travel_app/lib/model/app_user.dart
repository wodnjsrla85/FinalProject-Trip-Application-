import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String sex;       // "M" / "F" or "male"/"female" 등
  final int age;
  final String phone;
  final String address;
  final DateTime createdAt;
  final int mileage;      // 기본 0

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.sex,
    required this.age,
    required this.phone,
    required this.address,
    required this.createdAt,
    this.mileage = 0,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    return AppUser(
      uid: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      sex: map['sex'] ?? '',
      age: (map['age'] ?? 0) is int ? map['age'] : int.tryParse('${map['age']}') ?? 0,
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
      mileage: (map['mileage'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'sex': sex,
      'age': age,
      'phone': phone,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'mileage': mileage,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? sex,
    int? age,
    String? phone,
    String? address,
    DateTime? createdAt,
    int? mileage,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      mileage: mileage ?? this.mileage,
    );
  }
}
