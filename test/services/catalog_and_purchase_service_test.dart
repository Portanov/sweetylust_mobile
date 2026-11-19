import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sweetylust/models/product_model.dart';
import 'package:sweetylust/providers/cart_provider.dart';
import 'package:sweetylust/services/cart_service.dart';
import 'package:sweetylust/services/http_client.dart';
import 'package:sweetylust/services/product_service.dart';

import '../helpers/recording_http_client.dart';

Map<String, dynamic> productJson(int id, {String title = 'Producto'}) => {
  'id': id,
  'title': title,
  'description': 'Descripción',
  'image': 'image.png',
  'price': 99.50,
  'stock': 10,
  'category': 'juguetes',
  'created_at': '2026-01-01T00:00:00.000Z',
  'updated_at': '2026-01-01T00:00:00.000Z',
};

Map<String, dynamic> orderJson() => {
  'id': 501,
  'userId': 9,
  'addressId': 7,
  'total': 199.0,
  'status': 'procesando',
  'items': [],
  'tracking': [],
  'created_at': '2026-01-01T00:00:00.000Z',
};

void main() {
  test('ProductService envía filtros del catálogo al endpoint correcto', () async {
    late http.BaseRequest captured;
    final client = RecordingHttpClient((request) {
      captured = request;
      return jsonResponse({
        'products': [productJson(1)],
        'total': 1,
      });
    });
    final service = ProductService(
      httpClient: client,
      apiUrl: 'https://api.test',
    );

    final result = await service.getProducts(
      ProductFilters(
        search: 'rosa',
        category: ProductCategory.juguetes,
        minPrice: 50,
        maxPrice: 200,
        inStock: true,
      ),
    );

    expect(result.total, 1);
    expect(result.products.single.title, 'Producto');
    expect(captured.url.path, '/products');
    expect(captured.url.queryParameters['search'], 'rosa');
    expect(captured.url.queryParameters['category'], 'juguetes');
    expect(captured.url.queryParameters['inStock'], 'true');
  });

  test('ProductService convierte una respuesta de categorías en modelos', () async {
    final client = RecordingHttpClient((_) {
      return jsonResponse([
        {'category': 'juguetes', 'count': 4},
        {'category': 'lenceria', 'count': 2},
      ]);
    });
    final service = ProductService(httpClient: client, apiUrl: 'https://api.test');

    final categories = await service.getCategories();

    expect(categories.map((item) => item.category), [
      ProductCategory.juguetes,
      ProductCategory.lenceria,
    ]);
    expect(categories.map((item) => item.count), [4, 2]);
  });

  test('CartService registra la orden y conserva el id persistido', () async {
    late http.BaseRequest captured;
    final client = RecordingHttpClient((request) {
      captured = request;
      return jsonResponse(orderJson());
    });
    final service = CartService(httpClient: client, apiUrl: 'https://api.test');

    final order = await service.confirmPayment(7);

    expect(order.id, 501);
    expect(order.status, 'procesando');
    expect(captured.url.path, '/cart/confirm-payment');
    expect(captured is http.Request, isTrue);
    expect((captured as http.Request).body, contains('"addressId":7'));
  });

  test('CartNotifier no envía compras con cantidad fuera de rango', () async {
    final client = RecordingHttpClient(
      (_) => jsonResponse({'message': 'No debe llamarse'}),
    );
    final service = CartService(httpClient: client, apiUrl: 'https://api.test');
    final notifier = CartNotifier(service);

    expect(await notifier.addToCart(12, 0), isFalse);
    expect(await notifier.addToCart(12, -1), isFalse);
    expect(client.requests, isEmpty);
    notifier.dispose();
  });

  test('el servicio transforma un error HTTP en ApiException', () async {
    final client = RecordingHttpClient(
      (_) => jsonResponse({'message': 'Producto agotado'}, statusCode: 409),
    );
    final service = ProductService(httpClient: client, apiUrl: 'https://api.test');

    await expectLater(
      service.getProductById(99),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 409)
            .having((error) => error.message, 'message', 'Producto agotado'),
      ),
    );
  });

  test('soporta carga concurrente de consultas del catálogo', () async {
    var calls = 0;
    final client = RecordingHttpClient((_) {
      calls++;
      return jsonResponse({'products': [productJson(calls)], 'total': 1});
    });
    final service = ProductService(httpClient: client, apiUrl: 'https://api.test');

    final results = await Future.wait(
      List.generate(100, (_) => service.getProducts()),
    ).timeout(const Duration(seconds: 5));

    expect(results, hasLength(100));
    expect(calls, 100);
    expect(client.requests, hasLength(100));
  });
}
