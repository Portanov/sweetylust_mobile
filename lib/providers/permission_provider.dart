import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/models/permission_model.dart';
import 'package:sweetylust/services/permission_service.dart';
import 'package:sweetylust/services/ble_service.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

class PermissionState {
  final PermissionSettings settings;
  final bool isLoading;
  final String? error;

  PermissionState({required this.settings, this.isLoading = false, this.error});

  PermissionState copyWith({
    PermissionSettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return PermissionState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  factory PermissionState.initial() {
    return PermissionState(settings: PermissionSettings());
  }

  bool get hasNotificationsPermission => settings.notificationsGranted;
  bool get hasBluetoothPermission => settings.bluetoothGranted;
  bool get isBluetoothEnabled => settings.bluetoothEnabled;
}

class PermissionNotifier extends StateNotifier<PermissionState> {
  final PermissionService _service;

  PermissionNotifier(this._service) : super(PermissionState.initial());

  Future<void> initializePermissions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _service.initializePermissions();
      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> requestNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final granted = await _service.requestNotificationPermission();
      final settings = _service.getSettings();
      state = state.copyWith(settings: settings, isLoading: false);
      return granted;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> requestBluetooth() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final granted = await _service.requestBluetoothPermission();
      final settings = _service.getSettings();
      state = state.copyWith(settings: settings, isLoading: false);
      return granted;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> checkPermissions() async {
    try {
      final settings = await _service.checkAllPermissions();
      state = state.copyWith(settings: settings);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final permissionNotifierProvider =
    StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
      final service = ref.watch(permissionServiceProvider);
      return PermissionNotifier(service);
    });

final bleServiceProvider = Provider<BLEService>((ref) {
  return BLEService();
});
