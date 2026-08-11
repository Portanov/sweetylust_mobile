import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/services/ble_service.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import 'service_providers.dart';
import 'http_provider.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? tempToken;
  final String? userEmail;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.tempToken,
    this.userEmail,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? tempToken,
    String? userEmail,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      tempToken: tempToken ?? this.tempToken,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  factory AuthState.initial() => AuthState();
  factory AuthState.loading() => AuthState(isLoading: true);
  factory AuthState.error(String message) => AuthState(error: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;
  Timer? _sessionExpiryTimer;

  AuthNotifier(this._authService, this._ref) : super(AuthState.initial());

  @override
  void dispose() {
    _sessionExpiryTimer?.cancel();
    super.dispose();
  }

  Future<bool> initializeSession() async {
    final httpClient = _ref.read(httpClientProvider);
    final token = await httpClient.getToken();

    if (token == null || token.isEmpty) {
      await _clearSession(preserveToken: false);
      return false;
    }

    if (isJwtExpired(token)) {
      try {
        final bleService = BLEService();
        await bleService.disconnectDevice();
      } catch (e) {
        debugPrint('Error desconectando BLE: $e');
      }
      await _clearSession(preserveToken: false);
      return false;
    }

    final payload = parseJwtPayload(token);
    if (payload == null) {
      await _clearSession(preserveToken: false);
      return false;
    }

    _setAuthenticatedSession(
      token: token,
      user: User(
        id: payload.sub,
        username: payload.username,
        email: payload.email,
        role: payload.role,
      ),
      payload: payload,
    );

    await _initializeNotificationsAfterSession();

    return true;
  }

  void _setAuthenticatedSession({
    required String token,
    required User user,
    required JwtPayload payload,
  }) {
    _sessionExpiryTimer?.cancel();

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(payload.exp * 1000);
    final remaining = expiresAt.difference(DateTime.now());

    if (remaining.isNegative || remaining == Duration.zero) {
      _expireSession();
      return;
    }

    _sessionExpiryTimer = Timer(remaining, _expireSession);

    state = state.copyWith(
      isLoading: false,
      user: user,
      token: token,
      isAuthenticated: true,
      tempToken: null,
      userEmail: null,
      error: null,
    );
  }

  Future<void> _clearSession({required bool preserveToken}) async {
    _sessionExpiryTimer?.cancel();
    _sessionExpiryTimer = null;

    if (!preserveToken) {
      final httpClient = _ref.read(httpClientProvider);
      await httpClient.deleteToken();
    }

    state = AuthState.initial();
  }

  Future<void> _expireSession() async {
    await _clearSession(preserveToken: false);
  }

  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.register(request);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> loginFirstStep(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = LoginFirstStepRequest(email: email, password: password);
      final response = await _authService.loginFirstStep(request);

      state = state.copyWith(
        isLoading: false,
        tempToken: response.tempToken,
        userEmail: email,
        error: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        tempToken: null,
      );
      return false;
    }
  }

  Future<void> _initializeNotificationsAfterSession() async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.initialize();
      await notificationService.registerCurrentDevice();
    } catch (e) {
      print('Error inicializando notificaciones después de sesión: $e');
    }
  }

   Future<void> _initializeNotificationsAfterLogin() async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.initialize();
      await notificationService.registerCurrentDevice();
    } catch (e) {
      print('Error al inicializar notificaciones después del login: $e');
    }
  }

  Future<bool> verifyPin(String pin) async {
    final email = state.userEmail;
    final tempToken = state.tempToken;

    if (email == null || tempToken == null) {
      state = state.copyWith(error: 'Información de sesión no encontrada');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = VerifyPinRequest(
        email: email,
        pin: pin,
        tempToken: tempToken,
      );

      final response = await _authService.verifyPin(request);

      final accessToken = response.accessToken;
      if (accessToken.isEmpty) {
        throw Exception('El token recibido está vacío');
      }

      final payload = parseJwtPayload(accessToken);
      if (payload == null || isJwtExpired(accessToken)) {
        throw Exception('El token recibido no es válido o ya expiró');
      }

      final httpClient = _ref.read(httpClientProvider);
      await httpClient.saveToken(accessToken);

      final hasToken = await httpClient.hasToken();

      if (!hasToken) {
        throw Exception('El token no se guardó correctamente');
      }

      _setAuthenticatedSession(
        token: accessToken,
        user: response.user,
        payload: payload,
      );

      await _initializeNotificationsAfterLogin();

      return true;
    } catch (e) {
      print('Error en verifyPin: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resendPinWithPassword(String password) async {
    final email = state.userEmail;
    if (email == null) {
      state = state.copyWith(error: 'Correo electrónico no encontrado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = LoginFirstStepRequest(email: email, password: password);
      final response = await _authService.loginFirstStep(request);

      state = state.copyWith(
        isLoading: false,
        tempToken: response.tempToken,
        error: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSession(preserveToken: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final currentTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
