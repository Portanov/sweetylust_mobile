// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PermissionSettings _$PermissionSettingsFromJson(Map<String, dynamic> json) =>
    PermissionSettings(
      notificationsGranted: json['notificationsGranted'] as bool? ?? false,
      bluetoothGranted: json['bluetoothGranted'] as bool? ?? false,
      bluetoothEnabled: json['bluetoothEnabled'] as bool? ?? false,
      lastChecked: json['lastChecked'] == null
          ? null
          : DateTime.parse(json['lastChecked'] as String),
    );

Map<String, dynamic> _$PermissionSettingsToJson(PermissionSettings instance) =>
    <String, dynamic>{
      'notificationsGranted': instance.notificationsGranted,
      'bluetoothGranted': instance.bluetoothGranted,
      'bluetoothEnabled': instance.bluetoothEnabled,
      'lastChecked': instance.lastChecked?.toIso8601String(),
    };
