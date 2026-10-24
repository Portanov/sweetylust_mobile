import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/http_client.dart';

final httpClientProvider = Provider<HttpClient>((ref) {
  return HttpClient(
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
