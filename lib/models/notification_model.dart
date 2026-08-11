import 'package:json_annotation/json_annotation.dart';
import 'package:sweetylust/helpers/model_helpers.dart';

part 'notification_model.g.dart';

enum DeviceType {
  @JsonValue('android')
  android('android'),
  @JsonValue('ios')
  ios('ios'),
  @JsonValue('web')
  web('web');

  final String value;
  const DeviceType(this.value);

  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeviceType.android,
    );
  }

  String toJson() => value;
}

@JsonSerializable()
class UserNotification {
  final String id;

  @JsonKey(name: 'userId')
  final int userId;

  @JsonKey(name: 'fcmToken')
  final String fcmToken;

  @JsonKey(name: 'deviceType')
  final DeviceType deviceType;

  @JsonKey(name: 'deviceName')
  final String? deviceName;

  @JsonKey(name: 'osVersion')
  final String? osVersion;

  @JsonKey(name: 'deviceId')
  final String? deviceId;

  @JsonKey(name: 'isActive')
  final int isActive;

  @JsonKey(name: 'isRevoked')
  final int isRevoked;

  @JsonKey(name: 'lastUsedAt')
  final DateTime? lastUsedAt;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  UserNotification({
    required this.id,
    required this.userId,
    required this.fcmToken,
    required this.deviceType,
    this.deviceName,
    this.osVersion,
    this.deviceId,
    required this.isActive,
    required this.isRevoked,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return UserNotification(
      id: parseString(safeJson['id']),
      userId: parseInt(safeJson['userId']),
      fcmToken: parseString(safeJson['fcmToken']),
      deviceType: DeviceType.fromString(parseString(safeJson['deviceType'])),
      deviceName: parseString(safeJson['deviceName']),
      osVersion: parseString(safeJson['osVersion']),
      deviceId: parseString(safeJson['deviceId']),
      isActive: parseInt(safeJson['isActive']),
      isRevoked: parseInt(safeJson['isRevoked']),
      lastUsedAt: parseDateTime(safeJson['lastUsedAt']),
      createdAt: parseDateTime(safeJson['createdAt']),
      updatedAt: parseDateTime(safeJson['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => _$UserNotificationToJson(this);
}

@JsonSerializable()
class RegisterDeviceRequest {
  @JsonKey(name: 'fcmToken')
  final String fcmToken;

  @JsonKey(name: 'deviceType')
  final DeviceType deviceType;

  @JsonKey(name: 'deviceName')
  final String? deviceName;

  @JsonKey(name: 'osVersion')
  final String? osVersion;

  @JsonKey(name: 'deviceId')
  final String? deviceId;

  RegisterDeviceRequest({
    required this.fcmToken,
    required this.deviceType,
    this.deviceName,
    this.osVersion,
    this.deviceId,
  });

  factory RegisterDeviceRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterDeviceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDeviceRequestToJson(this);
}

@JsonSerializable()
class RegisterDeviceResponse {
  final String message;

  @JsonKey(name: 'device')
  final UserNotification device;

  RegisterDeviceResponse({required this.message, required this.device});

  factory RegisterDeviceResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return RegisterDeviceResponse(
      message: parseString(safeJson['message']),
      device: UserNotification.fromJson(safeJson['device']),
    );
  }

  Map<String, dynamic> toJson() => _$RegisterDeviceResponseToJson(this);
}

@JsonSerializable()
class GetDevicesResponse {
  @JsonKey(name: 'devices')
  final List<UserNotification> devices;

  @JsonKey(name: 'count')
  final int count;

  GetDevicesResponse({required this.devices, required this.count});

  factory GetDevicesResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    List<UserNotification> devices = [];
    if (safeJson['devices'] is List) {
      devices = (safeJson['devices'] as List)
          .map(
            (item) => UserNotification.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return GetDevicesResponse(
      devices: devices,
      count: parseInt(safeJson['count']),
    );
  }

  Map<String, dynamic> toJson() => _$GetDevicesResponseToJson(this);
}

@JsonSerializable()
class SendTestNotificationRequest {
  final String title;
  final String body;
  final Map<String, String>? data;

  SendTestNotificationRequest({
    required this.title,
    required this.body,
    this.data,
  });

  factory SendTestNotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$SendTestNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendTestNotificationRequestToJson(this);
}

@JsonSerializable()
class SendTestNotificationResponse {
  final String message;
  final NotificationResult result;

  SendTestNotificationResponse({required this.message, required this.result});

  factory SendTestNotificationResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return SendTestNotificationResponse(
      message: parseString(safeJson['message']),
      result: NotificationResult.fromJson(safeJson['result']),
    );
  }

  Map<String, dynamic> toJson() => _$SendTestNotificationResponseToJson(this);
}

@JsonSerializable()
class NotificationResult {
  final int success;
  final int failed;
  final List<String> errors;

  NotificationResult({
    required this.success,
    required this.failed,
    required this.errors,
  });

  factory NotificationResult.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    List<String> errors = [];
    if (safeJson['errors'] is List) {
      errors = (safeJson['errors'] as List).map((e) => e.toString()).toList();
    }

    return NotificationResult(
      success: parseInt(safeJson['success']),
      failed: parseInt(safeJson['failed']),
      errors: errors,
    );
  }

  Map<String, dynamic> toJson() => _$NotificationResultToJson(this);
}

@JsonSerializable()
class DeviceStatsResponse {
  @JsonKey(name: 'totalDevices')
  final int totalDevices;

  @JsonKey(name: 'activeDevices')
  final int activeDevices;

  @JsonKey(name: 'byPlatform')
  final Map<String, int> byPlatform;

  DeviceStatsResponse({
    required this.totalDevices,
    required this.activeDevices,
    required this.byPlatform,
  });

  factory DeviceStatsResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    final Map<String, int> platformStats = {};
    if (safeJson['byPlatform'] is Map) {
      (safeJson['byPlatform'] as Map).forEach((key, value) {
        platformStats[key.toString()] = parseInt(value);
      });
    }

    return DeviceStatsResponse(
      totalDevices: parseInt(safeJson['totalDevices']),
      activeDevices: parseInt(safeJson['activeDevices']),
      byPlatform: platformStats,
    );
  }

  Map<String, dynamic> toJson() => _$DeviceStatsResponseToJson(this);
}
