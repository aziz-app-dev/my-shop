import 'dart:convert';

UserRequestModel userRequestModelFromJson(String str) =>
    UserRequestModel.fromJson(json.decode(str));

String userRequestModelToJson(UserRequestModel data) =>
    json.encode(data.toJson());

class UserRequestModel {
  final String email;
  final String password;

  UserRequestModel({
    required this.email,
    required this.password,
  });

  UserRequestModel copyWith({
    String? email,
    String? password,
  }) =>
      UserRequestModel(
        email: email ?? this.email,
        password: password ?? this.password,
      );

  factory UserRequestModel.fromJson(Map<String, dynamic> json) =>
      UserRequestModel(
        email: json["email"],
        password: json["password"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
      };
}
