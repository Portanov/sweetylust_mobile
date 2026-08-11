import 'package:json_annotation/json_annotation.dart';

part 'permission_model.g.dart';

@JsonSerializable()
class PermissionSettings {
  final bool notificationsGranted;
  final bool bluetoothGranted;
  final bool bluetoothEnabled;
  final DateTime? lastChecked;

  PermissionSettings({
    this.notificationsGranted = false,
    this.bluetoothGranted = false,
    this.bluetoothEnabled = false,
    this.lastChecked,
  });

  factory PermissionSettings.fromJson(Map<String, dynamic> json) =>
      _$PermissionSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionSettingsToJson(this);

  PermissionSettings copyWith({
    bool? notificationsGranted,
    bool? bluetoothGranted,
    bool? bluetoothEnabled,
    DateTime? lastChecked,
  }) {
    return PermissionSettings(
      notificationsGranted: notificationsGranted ?? this.notificationsGranted,
      bluetoothGranted: bluetoothGranted ?? this.bluetoothGranted,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}
