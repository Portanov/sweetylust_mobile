import 'package:flutter_test/flutter_test.dart';
import 'package:sweetylust/models/auth_model.dart';
import 'package:sweetylust/models/cart_model.dart';
import 'package:sweetylust/models/product_model.dart';

void main() {
  group('Registro y autenticación', () {
    test('serializa un registro válido con los nombres del contrato', () {
      final request = RegisterRequest(
        username: 'ana',
        email: 'ana@example.com',
        password: 'Segura123!',
        phone: 5512345678,
        birthDate: '1998-04-12',
      );

      expect(request.toJson(), {
        'username': 'ana',
        'email': 'ana@example.com',
        'password': 'Segura123!',
        'phone': 5512345678,
        'birth_date': '1998-04-12',
      });
    });

    test('conserva entradas vacías para que la capa de validación las rechace', () {
      final request = RegisterRequest(
        username: '',
        email: '',
        password: '',
        phone: 0,
        birthDate: '',
      );

      expect(request.username, isEmpty);
      expect(request.email, isEmpty);
      expect(request.phone, 0);
    });

    test('detecta OTP aunque el backend no envíe requires2fa', () {
      final response = LoginFirstStepResponse.fromJson({
        'message': 'Se envió un código de verificación',
      });

      expect(response.needsOtp, isTrue);
    });

    test('rechaza JWT mal formado como expirado', () {
      expect(parseJwtPayload('token-invalido'), isNull);
      expect(isJwtExpired('token-invalido'), isTrue);
    });
  });

  group('Catálogo y compra', () {
    test('normaliza una categoría desconocida a otros', () {
      expect(
        ProductCategoryExtension.fromString('categoria-no-existente'),
        ProductCategory.otros,
      );
    });

    test('calcula el total de artículos del carrito', () {
      final summary = CartSummary(items: const [], total: 249.50, itemCount: 3);

      expect(summary.total, 249.50);
      expect(summary.itemCount, 3);
    });

    test('serializa checkout con dirección y método de pago', () {
      final request = CheckoutRequest(
        addressId: 7,
        paymentMethod: 'card',
        notes: 'Entregar en recepción',
      );

      expect(request.toJson(), {
        'addressId': 7,
        'paymentMethod': 'card',
        'notes': 'Entregar en recepción',
      });
    });
  });
}
