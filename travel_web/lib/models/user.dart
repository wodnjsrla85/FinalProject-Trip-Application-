class AppUser {
  final String email;
  final String password;

  AppUser({
    required this.email, 
    required this.password
    }
  );

  factory AppUser.fromMap(String email, Map<String, dynamic> map) {
    return AppUser(
      email: email,
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'password': password,
      };
}