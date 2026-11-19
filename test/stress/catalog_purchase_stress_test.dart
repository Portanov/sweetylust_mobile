import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sweetylust/services/cart_service.dart';
import 'package:sweetylust/services/product_service.dart';

import '../helpers/recording_http_client.dart';

Map<String, dynamic> _product(int id) => {
  'id': id,
  'title': 'Producto $id',
  'description': 'Producto de prueba de estrés',
  'image': 'stress.png',
  'price': 120.0,
  'stock': 100,
  'category': 'juguetes',
  'created_at': '2026-01-01T00:00:00.000Z',
  'updated_at': '2026-01-01T00:00:00.000Z',
};

void main() {
  test('estrés de catálogo: atiende 250 consultas concurrentes', () async {
    var calls = 0;
    final client = RecordingHttpClient((request) {
      expect(request.url.path, '/products');
      final callId = ++calls;
      return jsonResponse({'products': [_product(callId)], 'total': 250});
    });
    final service = ProductService(httpClient: client, apiUrl: 'https://api.test');
    final stopwatch = Stopwatch()..start();

    final results = await Future.wait(
      List.generate(250, (_) => service.getProducts()),
    ).timeout(const Duration(seconds: 5));
    stopwatch.stop();

    expect(results, hasLength(250));
    expect(results.every((result) => result.products.length == 1), isTrue);
    expect(calls, 250);
    expect(client.requests, hasLength(250));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('estrés de compra: procesa 150 altas de carrito concurrentes', () async {
    var calls = 0;
    final client = RecordingHttpClient((request) {
      expect(request.url.path, '/cart/add');
      expect(request, isA<http.Request>());
      final body = jsonDecode((request as http.Request).body) as Map<String, dynamic>;
      expect(body['quantity'], 1);
      calls++;
      return jsonResponse({
        'summary': {'items': [], 'total': 120.0, 'itemCount': 1},
      });
    });
    final service = CartService(httpClient: client, apiUrl: 'https://api.test');
    final stopwatch = Stopwatch()..start();

    final results = await Future.wait(
      List.generate(150, (index) => service.addToCart(index + 1, 1)),
    ).timeout(const Duration(seconds: 5));
    stopwatch.stop();

    expect(results, hasLength(150));
    expect(results.every((response) => response.summary!.itemCount == 1), isTrue);
    expect(calls, 150);
    expect(client.requests, hasLength(150));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });
}
