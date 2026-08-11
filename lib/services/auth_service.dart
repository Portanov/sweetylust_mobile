import '../models/auth_model.dart';
import 'base_service.dart';
import 'http_client.dart';

class AuthService extends BaseService {
  AuthService({required super.httpClient, required super.apiUrl});

  @override
  String get basePath => '/auth';

  Future<RegisterResponse> register(RegisterRequest request) {
    return post<RegisterResponse>(
      '/register',
      fromJson: (json) => RegisterResponse.fromJson(json),
      body: request.toJson(),
    );
  }

  Future<LoginFirstStepResponse> loginFirstStep(
    LoginFirstStepRequest request,
  ) async {
    final endpoints = ['/login', '/login-first-step'];

    for (final endpoint in endpoints) {
      try {
        return await post<LoginFirstStepResponse>(
          endpoint,
          fromJson: (json) => LoginFirstStepResponse.fromJson(json),
          body: request.toJson(),
        );
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) {
          continue;
        }

        rethrow;
      }
    }

    throw ApiException(statusCode: 0, message: 'No se pudo completar el login');
  }

  Future<VerifyPinResponse> verifyPin(VerifyPinRequest request) {
    return post<VerifyPinResponse>(
      '/verify-pin',
      fromJson: (json) => VerifyPinResponse.fromJson(json),
      body: request.toJson(),
    );
  }
}
