// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
  id: (json['id'] as num).toInt(),
  productId: (json['productId'] as num).toInt(),
  product: Product.fromJson(json['product'] as Map<String, dynamic>),
  quantity: (json['quantity'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
  subtotal: (json['subtotal'] as num).toDouble(),
);

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'product': instance.product,
  'quantity': instance.quantity,
  'price': instance.price,
  'subtotal': instance.subtotal,
};

Cart _$CartFromJson(Map<String, dynamic> json) => Cart(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  total: (json['total'] as num).toDouble(),
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CartToJson(Cart instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'total': instance.total,
  'items': instance.items,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

CartSummary _$CartSummaryFromJson(Map<String, dynamic> json) => CartSummary(
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  itemCount: (json['itemCount'] as num).toInt(),
);

Map<String, dynamic> _$CartSummaryToJson(CartSummary instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'itemCount': instance.itemCount,
    };

CartResponse _$CartResponseFromJson(Map<String, dynamic> json) => CartResponse(
  message: json['message'] as String?,
  cart: json['cart'] == null
      ? null
      : Cart.fromJson(json['cart'] as Map<String, dynamic>),
  summary: json['summary'] == null
      ? null
      : CartSummary.fromJson(json['summary'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CartResponseToJson(CartResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'cart': instance.cart,
      'summary': instance.summary,
    };

AddToCartRequest _$AddToCartRequestFromJson(Map<String, dynamic> json) =>
    AddToCartRequest(
      productId: (json['productId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$AddToCartRequestToJson(AddToCartRequest instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
    };

UpdateCartItemRequest _$UpdateCartItemRequestFromJson(
  Map<String, dynamic> json,
) => UpdateCartItemRequest(quantity: (json['quantity'] as num).toInt());

Map<String, dynamic> _$UpdateCartItemRequestToJson(
  UpdateCartItemRequest instance,
) => <String, dynamic>{'quantity': instance.quantity};

CheckoutRequest _$CheckoutRequestFromJson(Map<String, dynamic> json) =>
    CheckoutRequest(
      addressId: (json['addressId'] as num).toInt(),
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$CheckoutRequestToJson(CheckoutRequest instance) =>
    <String, dynamic>{
      'addressId': instance.addressId,
      'paymentMethod': instance.paymentMethod,
      'notes': instance.notes,
    };

CheckoutResponse _$CheckoutResponseFromJson(Map<String, dynamic> json) =>
    CheckoutResponse(
      url: json['url'] as String,
      sessionId: json['sessionId'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$CheckoutResponseToJson(CheckoutResponse instance) =>
    <String, dynamic>{
      'url': instance.url,
      'sessionId': instance.sessionId,
      'message': instance.message,
    };

ConfirmPaymentResponse _$ConfirmPaymentResponseFromJson(
  Map<String, dynamic> json,
) => ConfirmPaymentResponse(
  message: json['message'] as String,
  orderId: (json['orderId'] as num).toInt(),
  status: json['status'] as String,
);

Map<String, dynamic> _$ConfirmPaymentResponseToJson(
  ConfirmPaymentResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'orderId': instance.orderId,
  'status': instance.status,
};

ConfirmOrderResponse _$ConfirmOrderResponseFromJson(
  Map<String, dynamic> json,
) => ConfirmOrderResponse(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  addressId: (json['addressId'] as num).toInt(),
  total: (json['total'] as num).toDouble(),
  status: json['status'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  tracking: (json['tracking'] as List<dynamic>)
      .map((e) => OrderTracking.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ConfirmOrderResponseToJson(
  ConfirmOrderResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'addressId': instance.addressId,
  'total': instance.total,
  'status': instance.status,
  'items': instance.items,
  'tracking': instance.tracking,
  'createdAt': instance.createdAt.toIso8601String(),
};

CreatePaymentIntentResponse _$CreatePaymentIntentResponseFromJson(
  Map<String, dynamic> json,
) => CreatePaymentIntentResponse(
  clientSecret: json['clientSecret'] as String,
  paymentIntentId: json['paymentIntentId'] as String,
  ephemeralKey: json['ephemeralKey'] as String?,
  customerId: json['customerId'] as String?,
);

Map<String, dynamic> _$CreatePaymentIntentResponseToJson(
  CreatePaymentIntentResponse instance,
) => <String, dynamic>{
  'clientSecret': instance.clientSecret,
  'paymentIntentId': instance.paymentIntentId,
  'ephemeralKey': instance.ephemeralKey,
  'customerId': instance.customerId,
};

ConfirmPaymentMobileResponse _$ConfirmPaymentMobileResponseFromJson(
  Map<String, dynamic> json,
) => ConfirmPaymentMobileResponse(
  paymentConfirmed: json['paymentConfirmed'] as bool,
);

Map<String, dynamic> _$ConfirmPaymentMobileResponseToJson(
  ConfirmPaymentMobileResponse instance,
) => <String, dynamic>{'paymentConfirmed': instance.paymentConfirmed};
