import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'http_client.dart';

abstract class BaseService {
  final http.Client _httpClient;
  final String _apiUrl;

  BaseService({required this._httpClient, required this._apiUrl});

  @protected
  http.Client get client => _httpClient;

  @protected
  String get apiUrl => _apiUrl;

  @protected
  String get basePath;

  Future<T> get<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final response = await _httpClient
        .get(uri)
        .timeout(const Duration(seconds: 30));
    return _handleResponse(response, fromJson);
  }

  Future<List<T>> getList<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final response = await _httpClient
        .get(uri)
        .timeout(const Duration(seconds: 30));
    return _handleListResponse(response, fromJson);
  }

  Future<T> post<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? body,
    bool parseResponse = true,
  }) async {
    final response = await _httpClient
        .post(
          _buildUri(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(response, fromJson, parseResponse: parseResponse);
  }

  Future<T> put<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient
        .put(
          _buildUri(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(response, fromJson);
  }

  Future<T> patch<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient
        .patch(
          _buildUri(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(response, fromJson);
  }

  Future<void> delete(String endpoint) async {
    final response = await _httpClient
        .delete(
          _buildUri(endpoint),
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 30));

    if (!_isSuccess(response)) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseError(response.body),
      );
    }
  }

  Future<T> deleteWithResponse<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final response = await _httpClient
        .delete(
          _buildUri(endpoint),
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(response, fromJson);
  }


  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final path = '$apiUrl$basePath$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(path).replace(queryParameters: queryParams);
    }
    return Uri.parse(path);
  }

  bool _isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson, {
    bool parseResponse = true,
  }) {
    if (_isSuccess(response)) {
      if (!parseResponse) {
        return fromJson({});
      }
      try {
        final data = jsonDecode(response.body);
        if (data is T) {
          return data;
        }
        if (data is Map<String, dynamic>) {
          return fromJson(data);
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Respuesta inesperada del servidor',
        );
      } catch (e) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Error al parsear respuesta: $e',
        );
      }
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _parseError(response.body),
    );
  }

  List<T> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (_isSuccess(response)) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Respuesta inesperada del servidor',
        );
      } catch (e) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Error al parsear respuesta: $e',
        );
      }
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _parseError(response.body),
    );
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final message = json['message'];
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
      return message?.toString() ?? 'Error desconocido';
    } catch (_) {
      return 'Error al procesar respuesta del servidor';
    }
  }
}
