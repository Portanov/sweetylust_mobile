import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'service_providers.dart';

class UserState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isUpdated;

  UserState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isUpdated = false,
  });

  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isUpdated,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isUpdated: isUpdated ?? this.isUpdated,
    );
  }

  factory UserState.initial() => UserState();
  factory UserState.loading() => UserState(isLoading: true);
  factory UserState.error(String message) => UserState(error: message);
}

class UserNotifier extends StateNotifier<UserState> {
  final UserService _service;
  final Ref _ref;

  UserNotifier(this._service, this._ref) : super(UserState.initial());

  Future<void> fetchProfile() async {
    state = UserState.loading();

    try {
      final user = await _service.getProfile();

      state = UserState(user: user, isLoading: false);
    } catch (e) {
      state = UserState.error(e.toString());
    }
  }

  Future<bool> updateProfile(UpdateProfileRequest request) async {
    print('🔄 Iniciando actualización de perfil...');
    state = state.copyWith(isLoading: true, error: null, isUpdated: false);

    try {
      final updatedUser = await _service.updateProfile(request);
      print('✅ Perfil actualizado: ${updatedUser.toJson()}');

      // ✅ Asegurar que el estado se actualiza correctamente
      state = UserState(user: updatedUser, isLoading: false, isUpdated: true);

      print('📊 Estado actualizado: isUpdated=${state.isUpdated}');
      return true;
    } catch (e) {
      print('❌ Error al actualizar perfil: $e');
      state = UserState(
        user: state.user,
        isLoading: false,
        error: e.toString(),
        isUpdated: false,
      );
      return false;
    }
  }

  Future<bool> changePassword(ChangePasswordRequest request) async {
    state = UserState.loading();

    try {
      await _service.changePassword(request);
      state = UserState(user: state.user, isLoading: false);
      return true;
    } catch (e) {
      state = UserState.error(e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetUpdated() {
    if (state.isUpdated) {
      state = state.copyWith(isUpdated: false);
    }
  }
}

final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((
  ref,
) {
  final service = ref.watch(userServiceProvider);
  return UserNotifier(service, ref);
});

final userProfileProvider = FutureProvider<User>((ref) async {
  final notifier = ref.watch(userNotifierProvider.notifier);
  await notifier.fetchProfile();
  return ref.watch(userNotifierProvider).user!;
});
