import 'dart:convert';
class userData{
  final String id;
  final String userName;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String token;

  userData({
    required this.id,
    required this.userName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    required this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'email': email,
      'token': token,
      'phone':phone,
      'role': role,
      'password': password,
    };
  }

  factory userData.fromMap(Map<String, dynamic> map) {
    return userData(
      id: map['_id'] ?? '',
      userName: map['userName'] ?? '',
      email: map['email'] ?? '',
      token: map['token'] ?? '',
      phone:map['phone']??'',
      role:map['role']??'',
      password: map['password'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory userData.fromJson(String source) => userData.fromMap(json.decode(source));
}

