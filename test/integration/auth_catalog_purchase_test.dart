import 'package:flutter_test/flutter_test.dart';
import 'package:sweetylust/models/auth_model.dart';
import 'package:sweetylust/services/auth_service.dart';
import 'package:sweetylust/services/cart_service.dart';
import 'package:sweetylust/services/product_service.dart';

import '../helpers/recording_http_client.dart';

void main() {
  test('flujo integrado registro → catálogo → carrito → compra', () async {
    final client = RecordingHttpClient((request) {
      final path = request.url.path;
      if (path == '/auth/register') {
        return jsonResponse({'message': 'Registro exitoso'}, statusCode: 201);
      }
      if (path == '/products') {
        return jsonResponse({
          'products': [
            {
              'id': 12,
              'title': 'Producto de prueba',
              'description': 'Demo',
              'image': 'demo.png',
              'price': 149.0,
              'stock': 8,
              'category': 'juguetes',
              'created_at': '2026-01-01T00:00:00.000Z',
              'updated_at': '2026-01-01T00:00:00.000Z',
            },
          ],
          'total': 1,
        });
      }
      if (path == '/cart/add') {
        return jsonResponse({
          'message': 'Agregado',
          'summary': {'items': [], 'total': 149.0, 'itemCount': 1},
        });
      }
      if (path == '/cart/confirm-payment') {
        return jsonResponse({
          'id': 700,
          'userId': 1,
          'addressId': 3,
          'total': 149.0,
          'status': 'procesando',
          'items': [],
          'tracking': [],
          'created_at': '2026-01-01T00:00:00.000Z',
        });
      }
      return jsonResponse({'message': 'Ruta no encontrada'}, statusCode: 404);
    });

    final auth = AuthService(httpClient: client, apiUrl: 'https://api.test');
    final products = ProductService(httpClient: client, apiUrl: 'https://api.test');
    final cart = CartService(httpClient: client, apiUrl: 'https://api.test');

    final registration = await auth.register(
      RegisterRequest(
        username: 'cliente',
        email: 'cliente@example.com',
        password: 'Segura123!',
        phone: 5512345678,
        birthDate: '1995-05-01',
      ),
    );
    final catalog = await products.getProducts();
    final cartResponse = await cart.addToCart(catalog.products.single.id, 1);
    final order = await cart.confirmPayment(3);

    expect(registration.message, 'Registro exitoso');
    expect(catalog.products.single.id, 12);
    expect(cartResponse.summary!.itemCount, 1);
    expect(order.id, 700);
    expect(order.total, 149.0);
    expect(client.requests.map((request) => request.url.path), [
      '/auth/register',
      '/products',
      '/cart/add',
      '/cart/confirm-payment',
    ]);
  });

  test('la comunicación informa credenciales inválidas sin ocultar el estado HTTP', () async {
    final client = RecordingHttpClient(
      (_) => jsonResponse({'message': 'Credenciales inválidas'}, statusCode: 401),
    );
    final auth = AuthService(httpClient: client, apiUrl: 'https://api.test');

    await expectLater(
      auth.loginFirstStep(
        LoginFirstStepRequest(email: 'bad@example.com', password: 'bad'),
      ),
      throwsA(isA<Object>()),
    );
  });

  test('el login reintenta la ruta alternativa cuando la API responde 404', () async {
    final paths = <String>[];
    final client = RecordingHttpClient((request) {
      paths.add(request.url.path);
      if (paths.length == 1) return jsonResponse({}, statusCode: 404);
      return jsonResponse({'message': 'Código enviado', 'requires2fa': true});
    });
    final auth = AuthService(httpClient: client, apiUrl: 'https://api.test');

    final response = await auth.loginFirstStep(
      LoginFirstStepRequest(email: 'cliente@example.com', password: 'Segura123!'),
    );

    expect(response.needsOtp, isTrue);
    expect(paths, ['/auth/login', '/auth/login-first-step']);
  });
}
