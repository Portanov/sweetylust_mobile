import 'dart:io' show File, Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sweetylust/services/product_service.dart';

String? _envValue(String key) {
  final processValue = Platform.environment[key];
  if (processValue != null && processValue.trim().isNotEmpty) {
    return processValue.trim();
  }

  final envFile = File('.env');
  if (!envFile.existsSync()) return null;

  for (final line in envFile.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final separator = trimmed.indexOf('=');
    if (separator <= 0 || trimmed.substring(0, separator).trim() != key) {
      continue;
    }

    var value = trimmed.substring(separator + 1).trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    return value;
  }
  return null;
}

Future<void> _pauseBetweenBatches() =>
    Future<void>.delayed(const Duration(milliseconds: 250));

void main() {
  test(
    'backend real: catálogo soporta 20 lecturas con concurrencia limitada',
    () async {
      final apiUrl = _envValue('API_URL');
      expect(apiUrl, isNotNull, reason: 'API_URL no está configurada');

      final httpClient = http.Client();
      addTearDown(httpClient.close);
      final service = ProductService(httpClient: httpClient, apiUrl: apiUrl!);

      const totalRequests = 20;
      const batchSize = 2;
      var completed = 0;

      for (var start = 0; start < totalRequests; start += batchSize) {
        final remaining = totalRequests - start;
        final currentBatch = remaining < batchSize ? remaining : batchSize;

        final results = await Future.wait(
          List.generate(currentBatch, (_) => service.getProducts()),
        );
        completed += results.length;

        expect(results, hasLength(currentBatch));
        expect(results.every((result) => result.total >= 0), isTrue);

        if (completed < totalRequests) {
          await _pauseBetweenBatches();
        }
      }

      expect(completed, totalRequests);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'backend real: categorías responde sin generar operaciones de escritura',
    () async {
      final apiUrl = _envValue('API_URL');
      expect(apiUrl, isNotNull, reason: 'API_URL no está configurada');

      final httpClient = http.Client();
      addTearDown(httpClient.close);
      final service = ProductService(httpClient: httpClient, apiUrl: apiUrl!);

      final categories = await service.getCategories();

      expect(categories, isNotNull);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
