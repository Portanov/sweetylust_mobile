// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  phone: (json['phone'] as num).toInt(),
  birthDate: json['birth_date'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'phone': instance.phone,
  'birth_date': instance.birthDate,
  'role': _$UserRoleEnumMap[instance.role]!,
  'created_at': instance.createdAt,
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.client: 'client',
  UserRole.employee: 'employee',
};

UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequest(
  username: json['username'] as String?,
  email: json['email'] as String?,
  phone: (json['phone'] as num?)?.toInt(),
  birthDate: json['birth_date'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  UpdateProfileRequest instance,
) => <String, dynamic>{
  'username': instance.username,
  'email': instance.email,
  'phone': instance.phone,
  'birth_date': instance.birthDate,
};

ChangePasswordRequest _$ChangePasswordRequestFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequest(
  currentPassword: json['current_password'] as String,
  newPassword: json['new_password'] as String,
);

Map<String, dynamic> _$ChangePasswordRequestToJson(
  ChangePasswordRequest instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'new_password': instance.newPassword,
};
