// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'role': instance.role,
};

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      phone: (json['phone'] as num).toInt(),
      birthDate: json['birth_date'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'phone': instance.phone,
      'birth_date': instance.birthDate,
    };

RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    RegisterResponse(message: json['message'] as String);

Map<String, dynamic> _$RegisterResponseToJson(RegisterResponse instance) =>
    <String, dynamic>{'message': instance.message};

LoginFirstStepRequest _$LoginFirstStepRequestFromJson(
  Map<String, dynamic> json,
) => LoginFirstStepRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginFirstStepRequestToJson(
  LoginFirstStepRequest instance,
) => <String, dynamic>{'email': instance.email, 'password': instance.password};

LoginFirstStepResponse _$LoginFirstStepResponseFromJson(
  Map<String, dynamic> json,
) => LoginFirstStepResponse(
  tempToken: json['tempToken'] as String,
  message: json['message'] as String,
  requires2fa: json['requires2fa'] as bool,
);

Map<String, dynamic> _$LoginFirstStepResponseToJson(
  LoginFirstStepResponse instance,
) => <String, dynamic>{
  'tempToken': instance.tempToken,
  'message': instance.message,
  'requires2fa': instance.requires2fa,
};

VerifyPinRequest _$VerifyPinRequestFromJson(Map<String, dynamic> json) =>
    VerifyPinRequest(
      email: json['email'] as String,
      pin: json['pin'] as String,
      tempToken: json['tempToken'] as String,
    );

Map<String, dynamic> _$VerifyPinRequestToJson(VerifyPinRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'pin': instance.pin,
      'tempToken': instance.tempToken,
    };

VerifyPinResponse _$VerifyPinResponseFromJson(Map<String, dynamic> json) =>
    VerifyPinResponse(
      accessToken: json['accessToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VerifyPinResponseToJson(VerifyPinResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'user': instance.user,
    };

JwtPayload _$JwtPayloadFromJson(Map<String, dynamic> json) => JwtPayload(
  sub: (json['sub'] as num).toInt(),
  email: json['email'] as String,
  role: json['role'] as String,
  username: json['username'] as String,
  exp: (json['exp'] as num).toInt(),
  iat: (json['iat'] as num).toInt(),
);

Map<String, dynamic> _$JwtPayloadToJson(JwtPayload instance) =>
    <String, dynamic>{
      'sub': instance.sub,
      'email': instance.email,
      'role': instance.role,
      'username': instance.username,
      'exp': instance.exp,
      'iat': instance.iat,
    };
