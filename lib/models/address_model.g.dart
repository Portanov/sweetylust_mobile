// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  recipientName: json['recipient_name'] as String,
  recipientPhone: json['recipient_phone'] as String,
  street: json['street'] as String,
  extNumber: json['ext_number'] as String,
  intNumber: json['int_number'] as String?,
  neighborhood: json['neighborhood'] as String,
  city: json['city'] as String,
  state: json['state'] as String,
  postalCode: json['postal_code'] as String,
  references: json['references'] as String?,
  isDefault: json['is_default'] as bool,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'recipient_name': instance.recipientName,
  'recipient_phone': instance.recipientPhone,
  'street': instance.street,
  'ext_number': instance.extNumber,
  'int_number': instance.intNumber,
  'neighborhood': instance.neighborhood,
  'city': instance.city,
  'state': instance.state,
  'postal_code': instance.postalCode,
  'references': instance.references,
  'is_default': instance.isDefault,
  'created_at': instance.createdAt,
};

CreateAddressRequest _$CreateAddressRequestFromJson(
  Map<String, dynamic> json,
) => CreateAddressRequest(
  recipientName: json['recipient_name'] as String,
  recipientPhone: json['recipient_phone'] as String,
  street: json['street'] as String,
  extNumber: json['ext_number'] as String,
  intNumber: json['int_number'] as String?,
  neighborhood: json['neighborhood'] as String,
  city: json['city'] as String,
  state: json['state'] as String,
  postalCode: json['postal_code'] as String,
  references: json['references'] as String?,
  isDefault: json['is_default'] as bool?,
);

Map<String, dynamic> _$CreateAddressRequestToJson(
  CreateAddressRequest instance,
) => <String, dynamic>{
  'recipient_name': instance.recipientName,
  'recipient_phone': instance.recipientPhone,
  'street': instance.street,
  'ext_number': instance.extNumber,
  'int_number': instance.intNumber,
  'neighborhood': instance.neighborhood,
  'city': instance.city,
  'state': instance.state,
  'postal_code': instance.postalCode,
  'references': instance.references,
  'is_default': instance.isDefault,
};

UpdateAddressRequest _$UpdateAddressRequestFromJson(
  Map<String, dynamic> json,
) => UpdateAddressRequest(
  recipientName: json['recipient_name'] as String?,
  recipientPhone: json['recipient_phone'] as String?,
  street: json['street'] as String?,
  extNumber: json['ext_number'] as String?,
  intNumber: json['int_number'] as String?,
  neighborhood: json['neighborhood'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  postalCode: json['postal_code'] as String?,
  references: json['references'] as String?,
  isDefault: json['is_default'] as bool?,
);

Map<String, dynamic> _$UpdateAddressRequestToJson(
  UpdateAddressRequest instance,
) => <String, dynamic>{
  'recipient_name': instance.recipientName,
  'recipient_phone': instance.recipientPhone,
  'street': instance.street,
  'ext_number': instance.extNumber,
  'int_number': instance.intNumber,
  'neighborhood': instance.neighborhood,
  'city': instance.city,
  'state': instance.state,
  'postal_code': instance.postalCode,
  'references': instance.references,
  'is_default': instance.isDefault,
};
