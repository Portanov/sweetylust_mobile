import '../models/cart_model.dart';
import 'base_service.dart';

class CartService extends BaseService {
  CartService({required super.httpClient, required super.apiUrl});

  @override
  String get basePath => '/cart';

  Future<CartResponse> getCart() {
    return get<CartResponse>(
      '',
      fromJson: (json) => CartResponse.fromJson(json),
    );
  }

  Future<CartResponse> addToCart(int productId, int quantity) {
    final request = AddToCartRequest(productId: productId, quantity: quantity);
    return post<CartResponse>(
      '/add',
      fromJson: (json) => CartResponse.fromJson(json),
      body: request.toJson(),
    );
  }

  Future<CartResponse> updateCartItem(int itemId, int quantity) {
    final request = UpdateCartItemRequest(quantity: quantity);
    return patch<CartResponse>(
      '/item/$itemId',
      fromJson: (json) => CartResponse.fromJson(json),
      body: request.toJson(),
    );
  }

  Future<CartResponse> removeFromCart(int itemId) {
    return deleteWithResponse<CartResponse>(
      '/item/$itemId',
      fromJson: (json) => CartResponse.fromJson(json),
    );
  }

  Future<CartResponse> clearCart() {
  return deleteWithResponse<CartResponse>(
    '/clear',
    fromJson: (json) => CartResponse.fromJson(json),
  );
}

  Future<CreatePaymentIntentResponse> createPaymentIntent(int addressId) {
    return post<CreatePaymentIntentResponse>(
      '/create-payment-intent',
      fromJson: (json) => CreatePaymentIntentResponse.fromJson(json),
      body: {'addressId': addressId},
    );
  }

  Future<ConfirmPaymentMobileResponse> confirmPaymentMobile(
    String paymentIntentId,
  ) {
    return post<ConfirmPaymentMobileResponse>(
      '/confirm-payment-intent',
      fromJson: (json) => ConfirmPaymentMobileResponse.fromJson(json),
      body: {'paymentIntentId': paymentIntentId},
    );
  }

  Future<ConfirmOrderResponse> confirmPayment(int addressId) {
    return post<ConfirmOrderResponse>(
      '/confirm-payment',
      fromJson: (json) => ConfirmOrderResponse.fromJson(json),
      body: {'addressId': addressId},
    );
  }
}
