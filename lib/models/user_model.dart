import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

String _readStringValue(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];
  if (value == null) return fallback;
  return value.toString();
}

int _readIntValue(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is num) return value.toInt();
  return fallback;
}

enum UserRole {
  @JsonValue('admin')
  admin,
  @JsonValue('client')
  client,
  @JsonValue('employee')
  employee,
}

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String email;
  final int phone;
  @JsonKey(name: 'birth_date')
  final String birthDate;
  final UserRole role;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _readIntValue(json, 'id'),
      username: _readStringValue(json, 'username'),
      email: _readStringValue(json, 'email'),
      phone: _readIntValue(json, 'phone'),
      birthDate: _readStringValue(json, 'birth_date', fallback: ''),
      role: UserRole.values.firstWhere(
        (value) => value.name == _readStringValue(json, 'role').toLowerCase(),
        orElse: () => UserRole.client,
      ),
      createdAt: _readStringValue(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'username': username,
    'email': email,
    'phone': phone,
    'birth_date': birthDate,
    'role': role.name,
    'created_at': createdAt,
  };
}

@JsonSerializable()
class UpdateProfileRequest {
  final String? username;
  final String? email;
  final int? phone;
  @JsonKey(name: 'birth_date')
  final String? birthDate;

  UpdateProfileRequest({this.username, this.email, this.phone, this.birthDate});

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) {
    return UpdateProfileRequest(
      username: _readStringValue(json, 'username'),
      email: _readStringValue(json, 'email'),
      phone: _readIntValue(json, 'phone'),
      birthDate: _readStringValue(json, 'birth_date'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'username': username,
    'email': email,
    'phone': phone,
    'birth_date': birthDate,
  };
}

@JsonSerializable()
class ChangePasswordRequest {
  @JsonKey(name: 'current_password')
  final String currentPassword;
  @JsonKey(name: 'new_password')
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) {
    return ChangePasswordRequest(
      currentPassword: _readStringValue(json, 'current_password'),
      newPassword: _readStringValue(json, 'new_password'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'current_password': currentPassword,
    'new_password': newPassword,
  };
}
