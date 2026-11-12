import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../services/http_client.dart';
import 'service_providers.dart';
import 'http_provider.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? userEmail;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.userEmail,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? userEmail,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
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
    // Cookies are intentionally kept out of persistent storage, so a new
    // process must authenticate again.
    return false;
  }

  void _setAuthenticatedSession({required User user}) {
    _sessionExpiryTimer?.cancel();

    state = state.copyWith(
      isLoading: false,
      user: user,
      isAuthenticated: true,
      userEmail: null,
      error: null,
    );
  }

  Future<void> _clearSession() async {
    _sessionExpiryTimer?.cancel();
    _sessionExpiryTimer = null;

    _ref.read(httpClientProvider).clearCookies();

    state = AuthState.initial();
  }

  Future<void> _expireSession() async {
    await _clearSession();
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
      await _authService.loginFirstStep(request);

      state = state.copyWith(isLoading: false, userEmail: email, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        userEmail: null,
        error: _authenticationErrorMessage(e),
      );
      return false;
    }
  }

  String _authenticationErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'El correo o la contraseña son incorrectos';
      }

      if (error.statusCode == 0) {
        return error.message;
      }

      return error.message;
    }

    return 'No se pudo iniciar sesión. Intenta nuevamente';
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
    if (email == null) {
      state = state.copyWith(error: 'Información de sesión no encontrada');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = VerifyPinRequest(email: email, pin: pin);

      final response = await _authService.verifyPin(request);

      _setAuthenticatedSession(user: response.user);

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

      state = state.copyWith(isLoading: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSession();
  }

  void clearError() {
    state = AuthState(
      user: state.user,
      token: state.token,
      isLoading: state.isLoading,
      isAuthenticated: state.isAuthenticated,
      userEmail: state.userEmail,
    );
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
