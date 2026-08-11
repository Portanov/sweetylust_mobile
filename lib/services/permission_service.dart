import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetylust/models/permission_model.dart';
import 'dart:convert';

class PermissionService {
  static const String _permissionsKey = 'permission_settings';
  static PermissionSettings? _cachedSettings;

  Future<PermissionSettings> initializePermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_permissionsKey);

    if (saved != null) {
      try {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        _cachedSettings = PermissionSettings.fromJson(json);
      } catch (e) {
        _cachedSettings = PermissionSettings();
      }
    } else {
      _cachedSettings = PermissionSettings();
    }

    await checkAllPermissions();
    return _cachedSettings!;
  }

  Future<PermissionSettings> checkAllPermissions() async {
    final notificationsGranted = await checkNotificationPermission();
    final bluetoothGranted = await checkBluetoothPermission();
    final bluetoothEnabled = await isBluetoothEnabled();

    _cachedSettings =
        _cachedSettings?.copyWith(
          notificationsGranted: notificationsGranted,
          bluetoothGranted: bluetoothGranted,
          bluetoothEnabled: bluetoothEnabled,
          lastChecked: DateTime.now(),
        ) ??
        PermissionSettings(
          notificationsGranted: notificationsGranted,
          bluetoothGranted: bluetoothGranted,
          bluetoothEnabled: bluetoothEnabled,
          lastChecked: DateTime.now(),
        );

    await _saveSettings();
    return _cachedSettings!;
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        final granted = result.isGranted;
        _cachedSettings = _cachedSettings?.copyWith(
          notificationsGranted: granted,
          lastChecked: DateTime.now(),
        );
        await _saveSettings();
        return granted;
      }
      return status.isGranted;
    } else {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        final granted = result.isGranted;
        _cachedSettings = _cachedSettings?.copyWith(
          notificationsGranted: granted,
          lastChecked: DateTime.now(),
        );
        await _saveSettings();
        return granted;
      }
      return status.isGranted;
    }
  }

  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    final granted = status.isGranted;
    _cachedSettings = _cachedSettings?.copyWith(notificationsGranted: granted);
    await _saveSettings();
    return granted;
  }

  Future<bool> requestBluetoothPermission() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        if (await Permission.location.shouldShowRequestRationale)
          Permission.locationWhenInUse,
      ];

      final results = await permissions.request();
      final allGranted = results.values.every((status) => status.isGranted);

      _cachedSettings = _cachedSettings?.copyWith(
        bluetoothGranted: allGranted,
        lastChecked: DateTime.now(),
      );
      await _saveSettings();
      return allGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.status;
      if (status.isDenied) {
        final result = await Permission.bluetooth.request();
        final granted = result.isGranted;
        _cachedSettings = _cachedSettings?.copyWith(
          bluetoothGranted: granted,
          lastChecked: DateTime.now(),
        );
        await _saveSettings();
        return granted;
      }
      return status.isGranted;
    }
    return false;
  }

  Future<bool> checkBluetoothPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.bluetooth.status;
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;

      final granted =
          status.isGranted && scanStatus.isGranted && connectStatus.isGranted;

      _cachedSettings = _cachedSettings?.copyWith(bluetoothGranted: granted);
      await _saveSettings();
      return granted;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.status;
      final granted = status.isGranted;
      _cachedSettings = _cachedSettings?.copyWith(bluetoothGranted: granted);
      await _saveSettings();
      return granted;
    }
    return false;
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      if (Platform.isIOS) {
        return await _checkBluetoothState();
      } else {
        final status = await Permission.bluetooth.status;
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking bluetooth enabled: $e');
      return false;
    }
  }

  Future<bool> _checkBluetoothState() async {
    try {
      final isAvailable = await _isBluetoothAvailable();
      return isAvailable;
    } catch (e) {
      debugPrint('Error checking bluetooth state: $e');
      return false;
    }
  }

  Future<bool> _isBluetoothAvailable() async {
    return true;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_cachedSettings != null) {
      final json = jsonEncode(_cachedSettings!.toJson());
      await prefs.setString(_permissionsKey, json);
    }
  }

  PermissionSettings getSettings() {
    return _cachedSettings ?? PermissionSettings();
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsKey);
    _cachedSettings = PermissionSettings();
  }

  Future<bool> showBluetoothEnableDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bluetooth Desactivado'),
            content: const Text(
              'Por favor, activa el Bluetooth para poder conectar tu dispositivo wearable.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Abrir Ajustes'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
