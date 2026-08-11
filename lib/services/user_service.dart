import '../models/user_model.dart';
import 'base_service.dart';

class UserService extends BaseService {
  UserService({required super.httpClient, required super.apiUrl});

  @override
  String get basePath => '/users';

  Future<User> getProfile() {
    return get<User>('/me', fromJson: (json) => User.fromJson(json));
  }

  Future<User> updateProfile(UpdateProfileRequest request) {
    return put<User>(
      '/me',
      fromJson: (json) => User.fromJson(json),
      body: request.toJson(),
    );
  }

  Future<void> changePassword(ChangePasswordRequest request) {
    return patch('/me/password', fromJson: (_) => {}, body: request.toJson());
  }

  Future<void> deleteUser(int userId) {
    return delete('/$userId');
  }
}
