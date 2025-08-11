// To parse this JSON data, do
//
//     final userRegisterRequest = userRegisterRequestFromJson(jsonString);

import 'dart:convert';

UserRegisterRequest userRegisterRequestFromJson(String str) => UserRegisterRequest.fromJson(json.decode(str));

String userRegisterRequestToJson(UserRegisterRequest data) => json.encode(data.toJson());

class UserRegisterRequest {
    String username;
    String email;
    String passwords;

    UserRegisterRequest({
        required this.username,
        required this.email,
        required this.passwords,
    });

    factory UserRegisterRequest.fromJson(Map<String, dynamic> json) => UserRegisterRequest(
        username: json["username"],
        email: json["email"],
        passwords: json["passwords"],
    );

    Map<String, dynamic> toJson() => {
        "username": username,
        "email": email,
        "passwords": passwords,
    };
}
