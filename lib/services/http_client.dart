
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic originalError;

  ApiException({
    required this.statusCode,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class HttpClient extends http.BaseClient {
  final FlutterSecureStorage _secureStorage;
  final String _tokenKey;
  final Duration _timeout;
  final bool _enableLogging;
  final http.Client _client;

  HttpClient({
    FlutterSecureStorage? secureStorage,
    this._tokenKey = 'jwt_token',
    this._timeout = const Duration(seconds: 30),
    this._enableLogging = true,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      if (request.method == 'DELETE' && request is http.Request) {
        request.body = '{}';
      }

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (_enableLogging) {
        _logRequest(request);
      }

      final streamedResponse = await _client
          .send(request)
          .timeout(
            _timeout,
            onTimeout: () {
              throw ApiException(
                statusCode: 0,
                message: 'Tiempo de espera agotado (${_timeout.inSeconds}s)',
              );
            },
          );

      if (_enableLogging) {
        _logResponse(streamedResponse);
      }

      return streamedResponse;
    } catch (e) {
      if (_enableLogging) {
        print('Error en HttpClient: $e');
      }
      rethrow;
    }
  }

  @override
  void close() {
    _client.close();
  }

  Future<String?> _getToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (_enableLogging) {
        print(
          'Leyendo token: ${token != null ? 'Token encontrado (${token.substring(0, 10)}...)' : 'No hay token'}',
        );
      }
      return token;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      if (_enableLogging) {
        print('💾 Guardando token: ${token.substring(0, 20)}...');
      }
      await _secureStorage.write(key: _tokenKey, value: token);

      final saved = await _secureStorage.read(key: _tokenKey);
      if (_enableLogging) {
        if (saved != null && saved.isNotEmpty) {
          print('Token guardado correctamente: ${saved.substring(0, 10)}...');
        } else {
          print('ERROR: El token NO se guardó correctamente');
        }
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      print('Error al eliminar token: $e');
      rethrow;
    }
  }

  Future<bool> hasToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final has = token != null && token.isNotEmpty;
      if (_enableLogging) {
        print('Verificando token: ${has ? 'Hay token' : 'No hay token'}');
      }
      return has;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    return await _getToken();
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
  }

  void _logRequest(http.BaseRequest request) {
    print('');
    print('╔════════════════════════════════════════════════════════════');
    print('║ 📤 REQUEST');
    print('╠════════════════════════════════════════════════════════════');
    print('║ Método: ${request.method}');
    print('║ URL: ${request.url}');

    if (request.headers.isNotEmpty) {
      print('║');
      print('║ Headers:');
      request.headers.forEach((key, value) {
        final displayValue = key.toLowerCase() == 'authorization'
            ? 'Bearer ****${value.length > 20 ? value.substring(value.length - 10) : ''}'
            : value;
        print('║   $key: $displayValue');
      });
    }

    if (request is http.Request && request.bodyBytes.isNotEmpty) {
      print('║');
      try {
        final decoded = utf8.decode(request.bodyBytes);
        final json = jsonDecode(decoded);
        print('║ Body: ${_truncate(jsonEncode(json), 200)}...');
      } catch (_) {
        print('║ Body: ${_truncate(request.body, 200)}...');
      }
    }

    print('╚════════════════════════════════════════════════════════════');
    print('');
  }

  void _logResponse(http.StreamedResponse response) {
    print('');
    print('╔════════════════════════════════════════════════════════════');
    print('║ 📥 RESPONSE');
    print('╠════════════════════════════════════════════════════════════');
    print('║ Status: ${response.statusCode}');
    print('║ URL: ${response.request?.url}');

    if (response.headers.isNotEmpty) {
      print('║');
      print('║ Headers:');
      response.headers.forEach((key, value) {
        print('║   $key: $value');
      });
    }

    print('╚════════════════════════════════════════════════════════════');
    print('');
  }
}

extension HttpResponseExt on http.Response {
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  bool get isClientError => statusCode >= 400 && statusCode < 500;

  bool get isServerError => statusCode >= 500 && statusCode < 600;

  Map<String, dynamic> get jsonBody {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        statusCode: statusCode,
        message: 'Error al parsear JSON: $e',
      );
    }
  }

  List<dynamic> get jsonBodyList {
    try {
      return jsonDecode(body) as List<dynamic>;
    } catch (e) {
      throw ApiException(
        statusCode: statusCode,
        message: 'Error al parsear JSON: $e',
      );
    }
  }

  String get errorMessage {
    try {
      if (body.isEmpty) return 'Error sin mensaje';
      final json = jsonBody;
      if (json.containsKey('message')) {
        final msg = json['message'];
        if (msg is List && msg.isNotEmpty) {
          return msg.first.toString();
        }
        return msg.toString();
      }
      return 'Error desconocido';
    } catch (_) {
      return 'Error desconocido';
    }
  }
}

class HttpHelper {
  final HttpClient client;

  HttpHelper(this.client);

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    try {
      final response = await client.get(uri);

      if (response.isSuccess) {
        return response.jsonBody;
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: response.errorMessage,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getJsonList(Uri uri) async {
    try {
      final response = await client.get(uri);

      if (response.isSuccess) {
        return response.jsonBodyList;
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: response.errorMessage,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await client.post(uri, body: jsonEncode(body));

      if (response.isSuccess) {
        return response.jsonBody;
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: response.errorMessage,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> putJson(
    Uri uri, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await client.put(uri, body: jsonEncode(body));

      if (response.isSuccess) {
        return response.jsonBody;
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: response.errorMessage,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patchJson(
    Uri uri, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await client.patch(uri, body: jsonEncode(body));

      if (response.isSuccess) {
        return response.jsonBody;
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: response.errorMessage,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(Uri uri) async {
    try {
      final response = await client.delete(uri);

      if (!response.isSuccess) {
        throw ApiException(
          statusCode: response.statusCode,
          message: response.errorMessage,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
