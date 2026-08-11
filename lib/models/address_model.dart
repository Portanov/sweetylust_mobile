import 'package:json_annotation/json_annotation.dart';

part 'address_model.g.dart';

@JsonSerializable()
class Address {
  final int id;
  final int userId;
  @JsonKey(name: 'recipient_name')
  final String recipientName;
  @JsonKey(name: 'recipient_phone')
  final String recipientPhone;
  final String street;
  @JsonKey(name: 'ext_number')
  final String extNumber;
  @JsonKey(name: 'int_number')
  final String? intNumber;
  final String neighborhood;
  final String city;
  final String state;
  @JsonKey(name: 'postal_code')
  final String postalCode;
  final String? references;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.recipientName,
    required this.recipientPhone,
    required this.street,
    required this.extNumber,
    this.intNumber,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.postalCode,
    this.references,
    required this.isDefault,
    this.createdAt,
  });

  Address copyWith({
    int? id,
    int? userId,
    String? recipientName,
    String? recipientPhone,
    String? street,
    String? extNumber,
    String? intNumber,
    String? neighborhood,
    String? city,
    String? state,
    String? postalCode,
    String? references,
    bool? isDefault,
    String? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      street: street ?? this.street,
      extNumber: extNumber ?? this.extNumber,
      intNumber: intNumber ?? this.intNumber,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      references: references ?? this.references,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable()
class CreateAddressRequest {
  @JsonKey(name: 'recipient_name')
  final String recipientName;
  @JsonKey(name: 'recipient_phone')
  final String recipientPhone;
  final String street;
  @JsonKey(name: 'ext_number')
  final String extNumber;
  @JsonKey(name: 'int_number')
  final String? intNumber;
  final String neighborhood;
  final String city;
  final String state;
  @JsonKey(name: 'postal_code')
  final String postalCode;
  final String? references;
  @JsonKey(name: 'is_default')
  final bool? isDefault;

  CreateAddressRequest({
    required this.recipientName,
    required this.recipientPhone,
    required this.street,
    required this.extNumber,
    this.intNumber,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.postalCode,
    this.references,
    this.isDefault,
  });

  factory CreateAddressRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAddressRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAddressRequestToJson(this);
}

@JsonSerializable()
class UpdateAddressRequest {
  @JsonKey(name: 'recipient_name')
  final String? recipientName;
  @JsonKey(name: 'recipient_phone')
  final String? recipientPhone;
  final String? street;
  @JsonKey(name: 'ext_number')
  final String? extNumber;
  @JsonKey(name: 'int_number')
  final String? intNumber;
  final String? neighborhood;
  final String? city;
  final String? state;
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  final String? references;
  @JsonKey(name: 'is_default')
  final bool? isDefault;

  UpdateAddressRequest({
    this.recipientName,
    this.recipientPhone,
    this.street,
    this.extNumber,
    this.intNumber,
    this.neighborhood,
    this.city,
    this.state,
    this.postalCode,
    this.references,
    this.isDefault,
  });

  factory UpdateAddressRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAddressRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateAddressRequestToJson(this);
}
