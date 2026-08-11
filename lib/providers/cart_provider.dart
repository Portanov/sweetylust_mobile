import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import 'service_providers.dart';

class CartState {
  final List<CartItem> items;
  final double total;
  final int itemCount;
  final bool isLoading;
  final String? error;
  final Cart? cart;

  CartState({
    this.items = const [],
    this.total = 0.0,
    this.itemCount = 0,
    this.isLoading = false,
    this.error,
    this.cart,
  });

  CartState copyWith({
    List<CartItem>? items,
    double? total,
    int? itemCount,
    bool? isLoading,
    String? error,
    Cart? cart,
  }) {
    return CartState(
      items: items ?? this.items,
      total: total ?? this.total,
      itemCount: itemCount ?? this.itemCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      cart: cart ?? this.cart,
    );
  }

  factory CartState.initial() => CartState();
  factory CartState.loading() => CartState(isLoading: true);
  factory CartState.error(String message) => CartState(error: message);
}

class CartNotifier extends StateNotifier<CartState> {
  final CartService _service;

  CartNotifier(this._service) : super(CartState.initial());

  Future<void> loadCart() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getCart();

      state = CartState(
        items: response.summary!.items,
        total: response.summary!.total,
        itemCount: response.summary!.itemCount,
        cart: response.cart,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addToCart(int productId, int quantity) async {
    if (quantity <= 0) return false;

    try {
      final response = await _service.addToCart(productId, quantity);

      state = CartState(
        items: response.summary!.items,
        total: response.summary!.total,
        itemCount: response.summary!.itemCount,
        cart: response.cart,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateQuantity(int itemId, int quantity) async {
    if (quantity < 1) return false;

    try {
      final response = await _service.updateCartItem(itemId, quantity);

      state = CartState(
        items: response.summary!.items,
        total: response.summary!.total,
        itemCount: response.summary!.itemCount,
        cart: response.cart,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());

      await loadCart();
      return false;
    }
  }

  Future<bool> removeItem(int itemId) async {
    try {
      final response = await _service.removeFromCart(itemId);

      if (response.summary != null) {
        state = CartState(
          items: response.summary!.items,
          total: response.summary!.total,
          itemCount: response.summary!.itemCount,
          cart: response.cart,
          isLoading: false,
        );
      } else {
        await loadCart();
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      final response = await _service.clearCart();

      if (response.summary != null) {
        state = CartState(
          items: response.summary!.items,
          total: response.summary!.total,
          itemCount: response.summary!.itemCount,
          cart: response.cart,
          isLoading: false,
        );
      } else {
        state = CartState.initial();
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<CreatePaymentIntentResponse?> createPaymentIntent(
    int addressId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.createPaymentIntent(addressId);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<ConfirmPaymentMobileResponse?> confirmPaymentMobile(
    String paymentIntentId,
  ) async {
    try {
      final response = await _service.confirmPaymentMobile(paymentIntentId);
      return response;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<ConfirmOrderResponse?> confirmPayment(int addressId) async {
    try {
      final response = await _service.confirmPayment(addressId);

      if (response.id > 0) {
        state = CartState.initial();
      }

      return response;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<ConfirmOrderResponse?> checkoutWithPaymentSheet(int addressId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final intentResponse = await _service.createPaymentIntent(addressId);

      if (intentResponse.clientSecret.isEmpty) {
        throw Exception('No se pudo crear el PaymentIntent');
      }

      await _initPaymentSheet(intentResponse);
      await _presentPaymentSheet();

      final verifyResponse = await _service.confirmPaymentMobile(
        intentResponse.paymentIntentId,
      );

      if (!verifyResponse.paymentConfirmed) {
        throw Exception('El pago no fue completado correctamente');
      }

      final orderResponse = await _service.confirmPayment(addressId);

      if (orderResponse.id <= 0) {
        throw Exception('No se pudo registrar la orden');
      }

      state = CartState.initial();

      return orderResponse;
    } on StripeException catch (e) {
      final isCanceled = e.error.code == FailureCode.Canceled;
      final errorMessage = isCanceled
          ? 'Pago cancelado por el usuario'
          : (e.error.message ?? 'Error en el pago');

      state = state.copyWith(isLoading: false);
      throw Exception(errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> _initPaymentSheet(
    CreatePaymentIntentResponse intentResponse,
  ) async {
    try {
      final params = SetupPaymentSheetParameters(
        paymentIntentClientSecret: intentResponse.clientSecret,
        merchantDisplayName: 'Sweety Lust',
        style: ThemeMode.dark,
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'MX',
          testEnv: true,
        ),
      );

      await Stripe.instance.initPaymentSheet(paymentSheetParameters: params);
    } catch (e) {
      throw Exception('Error al inicializar el pago: $e');
    }
  }

  Future<void> _presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = CartState.initial();
  }

  int get totalItems {
    return state.items.fold(0, (sum, item) => sum + item.quantity);
  }
}

final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartState>((
  ref,
) {
  final service = ref.watch(cartServiceProvider);
  return CartNotifier(service);
});

final cartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(cartNotifierProvider).items;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartNotifierProvider).total;
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).itemCount;
});

final cartIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(cartNotifierProvider).isLoading;
});

final cartErrorProvider = Provider<String?>((ref) {
  return ref.watch(cartNotifierProvider).error;
});

final cartTotalItemsProvider = Provider<int>((ref) {
  final notifier = ref.watch(cartNotifierProvider.notifier);
  return notifier.totalItems;
});

final cartFutureProvider = FutureProvider<CartState>((ref) async {
  final notifier = ref.watch(cartNotifierProvider.notifier);
  await notifier.loadCart();
  return ref.watch(cartNotifierProvider);
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartItemCountProvider) == 0;
});
