// To parse this JSON data, do
//
//     final userLoginRequest = userLoginRequestFromJson(jsonString);

import 'dart:convert';

UserLoginRequest userLoginRequestFromJson(String str) => UserLoginRequest.fromJson(json.decode(str));

String userLoginRequestToJson(UserLoginRequest data) => json.encode(data.toJson());

class UserLoginRequest {
    String email;
    String passwords;

    UserLoginRequest({
        required this.email,
        required this.passwords,
    });

    factory UserLoginRequest.fromJson(Map<String, dynamic> json) => UserLoginRequest(
        email: json["Email"],
        passwords: json["Password"],
    );

    Map<String, dynamic> toJson() => {
        "Email": email,
        "Password": passwords,
    };
}
