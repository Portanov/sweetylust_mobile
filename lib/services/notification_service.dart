import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetylust/models/notification_model.dart';
import 'package:sweetylust/services/base_service.dart';
import 'package:sweetylust/services/ble_service.dart';
import 'package:sweetylust/services/permission_service.dart';

class NotificationService extends BaseService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final PermissionService _permissionService = PermissionService();
  final BLEService _bleService = BLEService();
  static const String _fcmTokenKey = 'fcm_token';
  static const String _deviceRegisteredKey = 'device_registered';
  bool _isInitialized = false;

  NotificationService({required super.httpClient, required super.apiUrl});
  @override
  String get basePath => '/notifications';

  Future<RegisterDeviceResponse> registerDevice(RegisterDeviceRequest request) {
    return post<RegisterDeviceResponse>(
      '/register-device',
      fromJson: (json) => RegisterDeviceResponse.fromJson(json),
      body: request.toJson(),
    );
  }

  Future<GetDevicesResponse> getUserDevices() {
    return get<GetDevicesResponse>(
      '/devices',
      fromJson: (json) => GetDevicesResponse.fromJson(json),
    );
  }

  Future<void> disableDevice(String fcmToken) {
    return delete('/devices/$fcmToken');
  }

  Future<SendTestNotificationResponse> sendTestNotification({
    required String title,
    required String body,
    Map<String, String>? data,
  }) {
    final request = SendTestNotificationRequest(
      title: title,
      body: body,
      data: data,
    );
    return post<SendTestNotificationResponse>(
      '/send-test',
      fromJson: (json) => SendTestNotificationResponse.fromJson(json),
      body: request.toJson(),
    );
  }

  Future<DeviceStatsResponse> getDeviceStats() {
    return get<DeviceStatsResponse>(
      '/stats',
      fromJson: (json) => DeviceStatsResponse.fromJson(json),
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Notification service already initialized');
      return;
    }
    try {
      await _bleService.initialize();
      await _permissionService.initializePermissions();
      await _initializeLocalNotifications();
      final hasPermission = await _permissionService
          .checkNotificationPermission();
      if (!hasPermission) {
        await _permissionService.requestNotificationPermission();
      }
      await _setupFCM();

      _isInitialized = true;
      debugPrint('Notification Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      rethrow;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permisos de notificación concedidos');
    } else {
      debugPrint('Permisos de notificación denegados');
    }
  }

  Future<void> _setupFCM() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
    }

    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('Token actualizado: $newToken');
      _handleTokenRefresh(newToken);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpen(initialMessage);
    }
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final request = RegisterDeviceRequest(
        fcmToken: newToken,
        deviceType: Platform.isAndroid ? DeviceType.android : DeviceType.ios,
        deviceName: deviceInfo['deviceName'],
        osVersion: deviceInfo['osVersion'],
        deviceId: deviceInfo['deviceId'],
      );
      await registerDevice(request);
      debugPrint('Token actualizado en el servidor');
    } catch (e) {
      debugPrint('Error al actualizar token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Mensaje en foreground: ${message.notification?.title}');
    _showLocalNotification(message);
    _processMessage(message);
  }

  void _handleMessageOpen(RemoteMessage message) {
    debugPrint(
      'App abierta desde notificación: ${message.notification?.title}',
    );
    _processMessage(message);
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Mensaje en background: ${message.notification?.title}');
  }

  @override
  void _processMessage(RemoteMessage message) {
    final data = message.data;
    final route = data['route'] ?? '/';
    final userId = data['userId'];
    _sendToWearable(message);
  }

  Future<void> _sendToWearable(RemoteMessage message) async {
    try {
      if (!_bleService.isConnected) {
        return;
      }

      final wearableData = {
        'title': message.notification?.title ?? 'Notificación',
        'body': message.notification?.body ?? '',
        'type': 'push_notification',
        'timestamp': DateTime.now().toIso8601String(),
        'data': message.data,
        'notificationId': message.messageId ?? '',
        'priority': 'high',
      };

      final success = await _bleService.sendNotificationToWearable(
        wearableData,
      );

      if (success) {
        debugPrint('Notificación enviada al wearable exitosamente');
      } else {
        await Future.delayed(const Duration(seconds: 2));
        if (_bleService.isConnected) {
          await _bleService.sendNotificationToWearable(wearableData);
        }
      }
    } catch (e) {
      debugPrint('Error enviando al wearable: $e');
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload ?? '/';
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'sweetylust_channel',
          'Sweety Lust Notificaciones',
          channelDescription: 'Canal para notificaciones de Sweety Lust',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title ?? 'Notificación',
      notification.body ?? '',
      details,
      payload: message.data['route'] ?? '/',
    );
  }

  Future<Map<String, String?>> _getDeviceInfo() async {
    return {
      'deviceName': Platform.isAndroid ? 'Android Device' : 'iOS Device',
      'osVersion': Platform.operatingSystemVersion,
      'deviceId': await _getDeviceId(),
    };
  }

  Future<String?> _getDeviceId() async {
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> registerCurrentDevice() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized, initializing...');
      await initialize();
    }

    try {
      final token = await _fcm.getToken();
      if (token == null) {
        debugPrint('No FCM token available');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool(_deviceRegisteredKey) ?? false;
      final savedToken = prefs.getString(_fcmTokenKey);

      if (isRegistered && savedToken == token) {
        debugPrint('Device already registered with token');
        return;
      }

      final deviceInfo = await _getDeviceInfo();

      final request = RegisterDeviceRequest(
        fcmToken: token,
        deviceType: Platform.isAndroid ? DeviceType.android : DeviceType.ios,
        deviceName: deviceInfo['deviceName'],
        osVersion: deviceInfo['osVersion'],
        deviceId: deviceInfo['deviceId'],
      );

      final response = await registerDevice(request);
      debugPrint('✅ Device registered successfully: ${response.message}');

      await prefs.setString(_fcmTokenKey, token);
      await prefs.setBool(_deviceRegisteredKey, true);
    } catch (e) {
      debugPrint('Error registering device: $e');
      rethrow;
    }
  }

  Future<void> unregisterCurrentDevice() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await disableDevice(token);
        debugPrint('Dispositivo desactivado');
      }
    } catch (e) {
      debugPrint('Error al desactivar dispositivo: $e');
    }
  }
}
