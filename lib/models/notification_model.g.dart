// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserNotification _$UserNotificationFromJson(Map<String, dynamic> json) =>
    UserNotification(
      id: json['id'] as String,
      userId: (json['userId'] as num).toInt(),
      fcmToken: json['fcmToken'] as String,
      deviceType: $enumDecode(_$DeviceTypeEnumMap, json['deviceType']),
      deviceName: json['deviceName'] as String?,
      osVersion: json['osVersion'] as String?,
      deviceId: json['deviceId'] as String?,
      isActive: (json['isActive'] as num).toInt(),
      isRevoked: (json['isRevoked'] as num).toInt(),
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserNotificationToJson(UserNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'fcmToken': instance.fcmToken,
      'deviceType': instance.deviceType,
      'deviceName': instance.deviceName,
      'osVersion': instance.osVersion,
      'deviceId': instance.deviceId,
      'isActive': instance.isActive,
      'isRevoked': instance.isRevoked,
      'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$DeviceTypeEnumMap = {
  DeviceType.android: 'android',
  DeviceType.ios: 'ios',
  DeviceType.web: 'web',
};

RegisterDeviceRequest _$RegisterDeviceRequestFromJson(
  Map<String, dynamic> json,
) => RegisterDeviceRequest(
  fcmToken: json['fcmToken'] as String,
  deviceType: $enumDecode(_$DeviceTypeEnumMap, json['deviceType']),
  deviceName: json['deviceName'] as String?,
  osVersion: json['osVersion'] as String?,
  deviceId: json['deviceId'] as String?,
);

Map<String, dynamic> _$RegisterDeviceRequestToJson(
  RegisterDeviceRequest instance,
) => <String, dynamic>{
  'fcmToken': instance.fcmToken,
  'deviceType': instance.deviceType,
  'deviceName': instance.deviceName,
  'osVersion': instance.osVersion,
  'deviceId': instance.deviceId,
};

RegisterDeviceResponse _$RegisterDeviceResponseFromJson(
  Map<String, dynamic> json,
) => RegisterDeviceResponse(
  message: json['message'] as String,
  device: UserNotification.fromJson(json['device'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RegisterDeviceResponseToJson(
  RegisterDeviceResponse instance,
) => <String, dynamic>{'message': instance.message, 'device': instance.device};

GetDevicesResponse _$GetDevicesResponseFromJson(Map<String, dynamic> json) =>
    GetDevicesResponse(
      devices: (json['devices'] as List<dynamic>)
          .map((e) => UserNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$GetDevicesResponseToJson(GetDevicesResponse instance) =>
    <String, dynamic>{'devices': instance.devices, 'count': instance.count};

SendTestNotificationRequest _$SendTestNotificationRequestFromJson(
  Map<String, dynamic> json,
) => SendTestNotificationRequest(
  title: json['title'] as String,
  body: json['body'] as String,
  data: (json['data'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$SendTestNotificationRequestToJson(
  SendTestNotificationRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'body': instance.body,
  'data': instance.data,
};

SendTestNotificationResponse _$SendTestNotificationResponseFromJson(
  Map<String, dynamic> json,
) => SendTestNotificationResponse(
  message: json['message'] as String,
  result: NotificationResult.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SendTestNotificationResponseToJson(
  SendTestNotificationResponse instance,
) => <String, dynamic>{'message': instance.message, 'result': instance.result};

NotificationResult _$NotificationResultFromJson(Map<String, dynamic> json) =>
    NotificationResult(
      success: (json['success'] as num).toInt(),
      failed: (json['failed'] as num).toInt(),
      errors: (json['errors'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$NotificationResultToJson(NotificationResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'failed': instance.failed,
      'errors': instance.errors,
    };

DeviceStatsResponse _$DeviceStatsResponseFromJson(Map<String, dynamic> json) =>
    DeviceStatsResponse(
      totalDevices: (json['totalDevices'] as num).toInt(),
      activeDevices: (json['activeDevices'] as num).toInt(),
      byPlatform: Map<String, int>.from(json['byPlatform'] as Map),
    );

Map<String, dynamic> _$DeviceStatsResponseToJson(
  DeviceStatsResponse instance,
) => <String, dynamic>{
  'totalDevices': instance.totalDevices,
  'activeDevices': instance.activeDevices,
  'byPlatform': instance.byPlatform,
};
