import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/models/notification_model.dart';
import 'package:sweetylust/providers/http_provider.dart';
import '../services/notification_service.dart';

class NotificationState {
  final List<UserNotification> devices;
  final bool isLoading;
  final String? error;
  final bool isRegistered;

  NotificationState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
    this.isRegistered = false,
  });

  NotificationState copyWith({
    List<UserNotification>? devices,
    bool? isLoading,
    String? error,
    bool? isRegistered,
  }) {
    return NotificationState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  factory NotificationState.initial() => NotificationState();
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(NotificationState.initial());

  Future<void> loadDevices() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getUserDevices();
      state = state.copyWith(
        devices: response.devices,
        isLoading: false,
        isRegistered: response.devices.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> registerDevice(RegisterDeviceRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.registerDevice(request);

      await loadDevices();

      state = state.copyWith(isLoading: false, isRegistered: true);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> disableDevice(String fcmToken) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.disableDevice(fcmToken);
      final updatedDevices = state.devices
          .where((d) => d.fcmToken != fcmToken)
          .toList();

      state = state.copyWith(
        devices: updatedDevices,
        isLoading: false,
        isRegistered: updatedDevices.isNotEmpty,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<SendTestNotificationResponse?> sendTestNotification({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.sendTestNotification(
        title: title,
        body: body,
        data: data,
      );
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<DeviceStatsResponse?> getDeviceStats() async {
    try {
      return await _service.getDeviceStats();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = NotificationState.initial();
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final service = ref.watch(notificationServiceProvider);
      return NotificationNotifier(service);
    });

final notificationDevicesProvider = Provider<List<UserNotification>>((ref) {
  return ref.watch(notificationNotifierProvider).devices;
});

final notificationIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(notificationNotifierProvider).isLoading;
});

final notificationErrorProvider = Provider<String?>((ref) {
  return ref.watch(notificationNotifierProvider).error;
});

final notificationIsRegisteredProvider = Provider<bool>((ref) {
  return ref.watch(notificationNotifierProvider).isRegistered;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return NotificationService(httpClient: httpClient, apiUrl: apiUrl);
});
