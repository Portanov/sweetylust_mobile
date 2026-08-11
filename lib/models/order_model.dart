import 'package:json_annotation/json_annotation.dart';
import 'package:sweetylust/helpers/model_helpers.dart';
import 'package:sweetylust/models/product_model.dart';

part 'order_model.g.dart';

enum OrderStatus {
  @JsonValue('procesando')
  procesando,
  @JsonValue('confirmado')
  confirmado,
  @JsonValue('enviado')
  enviado,
  @JsonValue('en_camino')
  enCamino,
  @JsonValue('entregado')
  entregado,
  @JsonValue('cancelado')
  cancelado,
}

@JsonSerializable()
class OrderTracking {
  final int id;
  final int orderId;
  final String status;
  final String note;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  OrderTracking({
    required this.id,
    required this.orderId,
    required this.status,
    required this.note,
    required this.createdAt,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return OrderTracking(
      id: parseInt(safeJson['id']),
      orderId: parseInt(safeJson['orderId'] ?? safeJson['order_id']),
      status: parseString(safeJson['status']),
      note: parseString(safeJson['note']),
      createdAt: parseDateTime(safeJson['created_at']),
    );
  }

  Map<String, dynamic> toJson() => _$OrderTrackingToJson(this);
}

@JsonSerializable()
class ProductData {
  final int id;
  final String title;
  final String description;
  final String image;
  final double price;
  final int? stock;

  ProductData({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    this.stock,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    Offer? offer;
    if (safeJson['offer'] is Map) {
      offer = Offer.fromJson(safeJson['offer'] as Map<String, dynamic>);
    }

    return ProductData(
      id: parseInt(safeJson['id']),
      title: parseString(safeJson['title']),
      description: parseString(safeJson['description']),
      image: parseString(safeJson['image']),
      price: parsePrice(safeJson['price']),
      stock: safeJson['stock'] != null ? parseInt(safeJson['stock']) : null,
    );
  }

  Map<String, dynamic> toJson() => _$ProductDataToJson(this);
}

@JsonSerializable()
class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final ProductData product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    ProductData product;
    if (safeJson['product'] is Map) {
      product = ProductData.fromJson(
        safeJson['product'] as Map<String, dynamic>,
      );
    } else {
      product = ProductData(
        id: parseInt(safeJson['productId']),
        title: parseString(safeJson['productName'] ?? 'Producto'),
        description: '',
        image: '',
        price: 0.0,
        stock: 0,
      );
    }

    return OrderItem(
      id: parseInt(safeJson['id']),
      orderId: parseInt(safeJson['orderId'] ?? safeJson['order_id']),
      productId: parseInt(safeJson['productId'] ?? safeJson['product_id']),
      quantity: parseInt(safeJson['quantity']),
      unitPrice: parsePrice(safeJson['unit_price']),
      subtotal: parsePrice(safeJson['subtotal']),
      product: product,
    );
  }

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

@JsonSerializable()
class OrderAddress {
  @JsonKey(name: 'recipient_name')
  final String recipientName;
  @JsonKey(name: 'recipient_phone')
  final String recipientPhone;
  final String street;
  @JsonKey(name: 'ext_number')
  final String extNumber;
  @JsonKey(name: 'int_number')
  final String? intNumber;
  final String neighborhood;
  final String city;
  final String state;
  @JsonKey(name: 'postal_code')
  final String postalCode;

  OrderAddress({
    required this.recipientName,
    required this.recipientPhone,
    required this.street,
    required this.extNumber,
    this.intNumber,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) =>
      _$OrderAddressFromJson(json);
  Map<String, dynamic> toJson() => _$OrderAddressToJson(this);
}

@JsonSerializable()
class UserData {
  final int id;
  final String username;
  final String email;

  UserData({required this.id, required this.username, required this.email});

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

@JsonSerializable()
class Order {
  final int id;
  final String status;
  final double total;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final OrderAddress? address;
  final UserData? user;
  final List<OrderItem> items;
  final List<OrderTracking>? tracking;

  Order({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    this.address,
    this.user,
    required this.items,
    this.tracking,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    List<OrderItem> items = [];
    if (safeJson['items'] is List) {
      items = (safeJson['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<OrderTracking>? tracking;
    if (safeJson['tracking'] is List) {
      tracking = (safeJson['tracking'] as List)
          .map((item) => OrderTracking.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: parseInt(safeJson['id']),
      status: parseString(safeJson['status']),
      total: parsePrice(safeJson['total']),
      createdAt: parseDateTime(safeJson['created_at']),
      address: safeJson['address'] is Map
          ? OrderAddress.fromJson(safeJson['address'] as Map<String, dynamic>)
          : null,
      user: safeJson['user'] is Map
          ? UserData.fromJson(safeJson['user'] as Map<String, dynamic>)
          : null,
      items: items,
      tracking: tracking,
    );
  }

  Order copyWith({
    int? id,
    String? status,
    double? total,
    DateTime? createdAt,
    OrderAddress? address,
    UserData? user,
    List<OrderItem>? items,
    List<OrderTracking>? tracking,
  }) {
    return Order(
      id: id ?? this.id,
      status: status ?? this.status,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      user: user ?? this.user,
      items: items ?? this.items,
      tracking: tracking ?? this.tracking,
    );
  }

  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

@JsonSerializable()
class OrderResponse {
  final int id;
  final String status;
  final double total;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final OrderAddress? address;
  final List<OrderItem> items;
  final List<OrderTracking> tracking;

  OrderResponse({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    this.address,
    required this.items,
    required this.tracking,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
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

    return OrderResponse(
      id: parseInt(safeJson['id']),
      status: parseString(safeJson['status']),
      total: parsePrice(safeJson['total']),
      createdAt: parseDateTime(safeJson['created_at']),
      address: safeJson['address'] is Map
          ? OrderAddress.fromJson(safeJson['address'] as Map<String, dynamic>)
          : null,
      items: items,
      tracking: tracking,
    );
  }

  OrderResponse copyWith({
    int? id,
    String? status,
    double? total,
    DateTime? createdAt,
    OrderAddress? address,
    List<OrderItem>? items,
    List<OrderTracking>? tracking,
  }) {
    return OrderResponse(
      id: id ?? this.id,
      status: status ?? this.status,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      items: items ?? this.items,
      tracking: tracking ?? this.tracking,
    );
  }

  Map<String, dynamic> toJson() => _$OrderResponseToJson(this);
}

@JsonSerializable()
class CancelOrderResponse {
  final String message;
  final int orderId;

  CancelOrderResponse({required this.message, required this.orderId});

  factory CancelOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$CancelOrderResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CancelOrderResponseToJson(this);
}

@JsonSerializable()
class PublicTrackingResponse {
  final int orderId;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<OrderTracking> history;

  PublicTrackingResponse({
    required this.orderId,
    required this.status,
    required this.createdAt,
    required this.history,
  });

  factory PublicTrackingResponse.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);

    List<OrderTracking> history = [];
    if (safeJson['history'] is List) {
      history = (safeJson['history'] as List)
          .map((item) => OrderTracking.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return PublicTrackingResponse(
      orderId: parseInt(safeJson['orderId'] ?? safeJson['order_id']),
      status: parseString(safeJson['status']),
      createdAt: parseDateTime(safeJson['created_at']),
      history: history,
    );
  }

  Map<String, dynamic> toJson() => _$PublicTrackingResponseToJson(this);
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
