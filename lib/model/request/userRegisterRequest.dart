import 'dart:convert';

class UserRegisterRequest {
  final String username;
  final String email;
  final String passwords;

  UserRegisterRequest({
    required this.username,
    required this.email,
    required this.passwords,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'passwords': passwords,
      };
}

String userRegisterRequestToJson(UserRegisterRequest data) {
  return json.encode(data.toJson());
}
