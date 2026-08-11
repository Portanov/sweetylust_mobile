import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/http_client.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final httpClientProvider = Provider<HttpClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return HttpClient(
    secureStorage: secureStorage,
    tokenKey: 'jwt_token',
    timeout: const Duration(seconds: 30),
    enableLogging: true,
  );
});


final apiUrlProvider = Provider<String>((ref) {
  return dotenv.get('API_URL');
});

final httpHelperProvider = Provider<HttpHelper>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  return HttpHelper(httpClient);
});
