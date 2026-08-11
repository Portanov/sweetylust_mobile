import 'package:json_annotation/json_annotation.dart';
import 'package:sweetylust/helpers/model_helpers.dart';
import 'package:sweetylust/models/order_model.dart';
import 'product_model.dart';

part 'cart_model.g.dart';

@JsonSerializable()
class CartItem {
  final int id;
  final int productId;
  final Product product;
  final int quantity;
  final double price;
  final double subtotal;

  CartItem({
    required this.id,
    required this.productId,
    required this.product,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    Product product;
    final productData = json['product'];
    if (productData is Map) {
      try {
        final convertedMap = Map<String, dynamic>.from(productData);
        product = Product.fromJson(convertedMap);
      } catch (_) {
        product = Product(
          id: parseInt(json['productId'] ?? json['product_id']),
          title: parseString(json['productName']),
          description: '',
          image: '',
          price: parsePrice(json['price']),
          stock: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } else {
      product = Product(
        id: parseInt(json['productId'] ?? json['product_id']),
        title: parseString(json['productName'] ?? 'Producto'),
        description: '',
        image: '',
        price: parsePrice(json['price']),
        stock: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return CartItem(
      id: parseInt(json['id']),
      productId: parseInt(json['productId'] ?? json['product_id']),
      product: product,
      quantity: parseInt(json['quantity']),
      price: parsePrice(json['price']),
      subtotal: parsePrice(json['subtotal']),
    );
  }

  Map<String, dynamic> toJson() => _$CartItemToJson(this);
}

@JsonSerializable()
class Cart {
  final int id;
  final int userId;
  final double total;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.total,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    List<CartItem> items = [];
    if (safeJson['items'] is List) {
      items = (safeJson['items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Cart(
      id: parseInt(safeJson['id']),
      userId: parseInt(safeJson['userId'] ?? safeJson['user_id']),
      total: parsePrice(safeJson['total']),
      items: items,
      createdAt: parseDateTime(safeJson['createdAt'] ?? safeJson['created_at']),
      updatedAt: parseDateTime(safeJson['updatedAt'] ?? safeJson['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => _$CartToJson(this);
}

@JsonSerializable()
class CartSummary {
  final List<CartItem> items;
  final double total;
  final int itemCount;

  CartSummary({
    required this.items,
    required this.total,
    required this.itemCount,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    List<CartItem> items = [];
    if (safeJson['items'] is List) {
      items = (safeJson['items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return CartSummary(
      items: items,
      total: parsePrice(safeJson['total']),
      itemCount: parseInt(safeJson['itemCount'] ?? safeJson['item_count']),
    );
  }

  Map<String, dynamic> toJson() => _$CartSummaryToJson(this);
}

@JsonSerializable()
class CartResponse {
  final String? message;
  final Cart? cart;
  final CartSummary? summary;

  CartResponse({this.message, this.cart, this.summary});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    Cart? cart;
    if (safeJson['cart'] is Map) {
      cart = Cart.fromJson(safeJson['cart'] as Map<String, dynamic>);
    }

    CartSummary? summary;
    if (safeJson['summary'] is Map) {
      summary = CartSummary.fromJson(
        safeJson['summary'] as Map<String, dynamic>,
      );
    }

    if (summary == null && cart != null) {
      summary = CartSummary(
        items: cart.items,
        total: cart.total,
        itemCount: cart.items.length,
      );
    }

    return CartResponse(
      message: parseString(safeJson['message']),
      cart: cart,
      summary: summary ?? CartSummary(items: [], total: 0.0, itemCount: 0),
    );
  }

  Map<String, dynamic> toJson() => _$CartResponseToJson(this);
}

@JsonSerializable()
class AddToCartRequest {
  final int productId;
  final int quantity;

  AddToCartRequest({required this.productId, required this.quantity});

  factory AddToCartRequest.fromJson(Map<String, dynamic> json) =>
      _$AddToCartRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddToCartRequestToJson(this);
}

@JsonSerializable()
class UpdateCartItemRequest {
  final int quantity;

  UpdateCartItemRequest({required this.quantity});

  factory UpdateCartItemRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateCartItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateCartItemRequestToJson(this);
}

@JsonSerializable()
class CheckoutRequest {
  final int addressId;
  final String? paymentMethod;
  final String? notes;

  CheckoutRequest({required this.addressId, this.paymentMethod, this.notes});

  factory CheckoutRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CheckoutRequestToJson(this);
}

@JsonSerializable()
class CheckoutResponse {
  final String url;
  final String? sessionId;
  final String? message;

  CheckoutResponse({required this.url, this.sessionId, this.message});

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return CheckoutResponse(
      url: parseString(safeJson['url']),
      sessionId: parseString(safeJson['sessionId'] ?? safeJson['session_id']),
      message: parseString(safeJson['message']),
    );
  }

  Map<String, dynamic> toJson() => _$CheckoutResponseToJson(this);
}

@JsonSerializable()
class ConfirmPaymentResponse {
  final String message;
  final int orderId;
  final String status;

  ConfirmPaymentResponse({
    required this.message,
    required this.orderId,
    required this.status,
  });

  factory ConfirmPaymentResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return ConfirmPaymentResponse(
      message: parseString(safeJson['message']),
      orderId: parseInt(safeJson['orderId'] ?? safeJson['order_id']),
      status: parseString(safeJson['status']),
    );
  }

  Map<String, dynamic> toJson() => _$ConfirmPaymentResponseToJson(this);
}

@JsonSerializable()
class ConfirmOrderResponse {
  final int id;
  final int userId;
  final int addressId;
  final double total;
  final String status;
  final List<OrderItem> items;
  final List<OrderTracking> tracking;
  final DateTime createdAt;

  ConfirmOrderResponse({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.total,
    required this.status,
    required this.items,
    required this.tracking,
    required this.createdAt,
  });

  factory ConfirmOrderResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    List<OrderItem> items = [];
    if (safeJson['items'] is List) {
      items = (safeJson['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<OrderTracking> tracking = [];
    if (safeJson['tracking'] is List) {
      tracking = (safeJson['tracking'] as List)
          .map((item) => OrderTracking.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ConfirmOrderResponse(
      id: parseInt(safeJson['id']),
      userId: parseInt(safeJson['userId'] ?? safeJson['user_id']),
      addressId: parseInt(safeJson['addressId'] ?? safeJson['address_id']),
      total: parsePrice(safeJson['total']),
      status: parseString(safeJson['status']),
      items: items,
      tracking: tracking,
      createdAt: parseDateTime(safeJson['created_at']),
    );
  }

  Map<String, dynamic> toJson() => _$ConfirmOrderResponseToJson(this);
}

@JsonSerializable()
class CreatePaymentIntentResponse {
  final String clientSecret;
  final String paymentIntentId;
  final String? ephemeralKey;
  final String? customerId;

  CreatePaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    this.ephemeralKey,
    this.customerId,
  });

  factory CreatePaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return CreatePaymentIntentResponse(
      clientSecret: parseString(
        safeJson['clientSecret'] ?? safeJson['client_secret'],
      ),
      paymentIntentId: parseString(
        safeJson['paymentIntentId'] ?? safeJson['payment_intent_id'],
      ),
      ephemeralKey: parseString(
        safeJson['ephemeralKey'] ?? safeJson['ephemeral_key'],
      ),
      customerId: parseString(
        safeJson['customerId'] ?? safeJson['customer_id'],
      ),
    );
  }

  Map<String, dynamic> toJson() => _$CreatePaymentIntentResponseToJson(this);
}

@JsonSerializable()
class ConfirmPaymentMobileResponse {
  final bool paymentConfirmed;

  ConfirmPaymentMobileResponse({required this.paymentConfirmed});

  factory ConfirmPaymentMobileResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return ConfirmPaymentMobileResponse(
      paymentConfirmed: parseBool(
        safeJson['payment_confirmed'] ?? safeJson['paymentConfirmed'],
      ),
    );
  }

  Map<String, dynamic> toJson() => _$ConfirmPaymentMobileResponseToJson(this);
}
