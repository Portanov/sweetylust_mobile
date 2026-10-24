import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:sweetylust/helpers/model_helpers.dart';
part 'auth_model.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String email;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: readInt(json, 'id'),
      username: readString(json, 'username'),
      email: readString(json, 'email'),
      role: readString(json, 'role'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'username': username,
    'email': email,
    'role': role,
  };
}

@JsonSerializable()
class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final int phone;
  @JsonKey(name: 'birth_date')
  final String birthDate;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
    required this.birthDate,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      username: readString(json, 'username'),
      email: readString(json, 'email'),
      password: readString(json, 'password'),
      phone: readInt(json, 'phone'),
      birthDate: readString(json, 'birth_date', fallback: ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'username': username,
    'email': email,
    'password': password,
    'phone': phone,
    'birth_date': birthDate,
  };
}

@JsonSerializable()
class RegisterResponse {
  final String message;

  RegisterResponse({required this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(message: readString(json, 'message'));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'message': message};
}

@JsonSerializable()
class LoginFirstStepRequest {
  final String email;
  final String password;

  LoginFirstStepRequest({required this.email, required this.password});

  factory LoginFirstStepRequest.fromJson(Map<String, dynamic> json) {
    return LoginFirstStepRequest(
      email: readString(json, 'email'),
      password: readString(json, 'password'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'password': password,
  };
}

@JsonSerializable()
class LoginFirstStepResponse {
  final String message;
  final bool requires2fa;

  LoginFirstStepResponse({required this.message, required this.requires2fa});

  bool get needsOtp => requires2fa;

  factory LoginFirstStepResponse.fromJson(Map<String, dynamic> json) {
    final rawRequires2fa = json['requires2fa'];
    bool requires2fa = false;

    if (rawRequires2fa is bool) {
      requires2fa = rawRequires2fa;
    } else if (rawRequires2fa is String) {
      requires2fa = rawRequires2fa.toLowerCase() == 'true';
    } else if (rawRequires2fa is num) {
      requires2fa = rawRequires2fa != 0;
    }

    final message = readString(json, 'message').toLowerCase();

    if (!requires2fa) {
      requires2fa =
          message.contains('codigo') ||
          message.contains('otp') ||
          message.contains('código') ||
          message.contains('verific');
    }

    return LoginFirstStepResponse(
      message: readString(json, 'message'),
      requires2fa: requires2fa,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'message': message,
    'requires2fa': requires2fa,
  };
}

@JsonSerializable()
class VerifyPinRequest {
  final String email;
  final String pin;

  VerifyPinRequest({required this.email, required this.pin});

  factory VerifyPinRequest.fromJson(Map<String, dynamic> json) {
    return VerifyPinRequest(
      email: readString(json, 'email'),
      pin: readString(json, 'pin'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'pin': pin,
  };
}

@JsonSerializable()
class VerifyPinResponse {
  final User user;

  VerifyPinResponse({required this.user});

  factory VerifyPinResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPinResponse(
      user: User.fromJson(
        (json['user'] is Map<String, dynamic>)
            ? json['user'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'user': user};
}

@JsonSerializable()
class JwtPayload {
  final int sub;
  final String email;
  final String role;
  final String username;
  final int exp;
  final int iat;

  JwtPayload({
    required this.sub,
    required this.email,
    required this.role,
    required this.username,
    required this.exp,
    required this.iat,
  });

  factory JwtPayload.fromJson(Map<String, dynamic> json) =>
      _$JwtPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$JwtPayloadToJson(this);
}

JwtPayload? parseJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final normalized = base64Url.normalize(parts[1]);
    final payloadBytes = base64Url.decode(normalized);
    final payloadJson = utf8.decode(payloadBytes);
    final decoded = jsonDecode(payloadJson);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return JwtPayload.fromJson(decoded);
  } catch (_) {
    return null;
  }
}

bool isJwtExpired(String token) {
  final payload = parseJwtPayload(token);
  if (payload == null) return true;

  final expiresAt = DateTime.fromMillisecondsSinceEpoch(payload.exp * 1000);
  return !expiresAt.isAfter(DateTime.now());
}
