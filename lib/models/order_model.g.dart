// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderTracking _$OrderTrackingFromJson(Map<String, dynamic> json) =>
    OrderTracking(
      id: (json['id'] as num).toInt(),
      orderId: (json['orderId'] as num).toInt(),
      status: json['status'] as String,
      note: json['note'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OrderTrackingToJson(OrderTracking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'status': instance.status,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
    };

ProductData _$ProductDataFromJson(Map<String, dynamic> json) => ProductData(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  image: json['image'] as String,
  price: (json['price'] as num).toDouble(),
  stock: (json['stock'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProductDataToJson(ProductData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'image': instance.image,
      'price': instance.price,
      'stock': instance.stock,
    };

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: (json['id'] as num).toInt(),
  orderId: (json['orderId'] as num).toInt(),
  productId: (json['productId'] as num).toInt(),
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unitPrice'] as num).toDouble(),
  subtotal: (json['subtotal'] as num).toDouble(),
  product: ProductData.fromJson(json['product'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'productId': instance.productId,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'subtotal': instance.subtotal,
  'product': instance.product,
};

OrderAddress _$OrderAddressFromJson(Map<String, dynamic> json) => OrderAddress(
  recipientName: json['recipient_name'] as String,
  recipientPhone: json['recipient_phone'] as String,
  street: json['street'] as String,
  extNumber: json['ext_number'] as String,
  intNumber: json['int_number'] as String?,
  neighborhood: json['neighborhood'] as String,
  city: json['city'] as String,
  state: json['state'] as String,
  postalCode: json['postal_code'] as String,
);

Map<String, dynamic> _$OrderAddressToJson(OrderAddress instance) =>
    <String, dynamic>{
      'recipient_name': instance.recipientName,
      'recipient_phone': instance.recipientPhone,
      'street': instance.street,
      'ext_number': instance.extNumber,
      'int_number': instance.intNumber,
      'neighborhood': instance.neighborhood,
      'city': instance.city,
      'state': instance.state,
      'postal_code': instance.postalCode,
    };

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
);

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
};

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: (json['id'] as num).toInt(),
  status: json['status'] as String,
  total: (json['total'] as num).toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
  address: json['address'] == null
      ? null
      : OrderAddress.fromJson(json['address'] as Map<String, dynamic>),
  user: json['user'] == null
      ? null
      : UserData.fromJson(json['user'] as Map<String, dynamic>),
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  tracking: (json['tracking'] as List<dynamic>?)
      ?.map((e) => OrderTracking.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'total': instance.total,
  'created_at': instance.createdAt.toIso8601String(),
  'address': instance.address,
  'user': instance.user,
  'items': instance.items,
  'tracking': instance.tracking,
};

OrderResponse _$OrderResponseFromJson(Map<String, dynamic> json) =>
    OrderResponse(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      address: json['address'] == null
          ? null
          : OrderAddress.fromJson(json['address'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracking: (json['tracking'] as List<dynamic>)
          .map((e) => OrderTracking.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderResponseToJson(OrderResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'total': instance.total,
      'created_at': instance.createdAt.toIso8601String(),
      'address': instance.address,
      'items': instance.items,
      'tracking': instance.tracking,
    };

CancelOrderResponse _$CancelOrderResponseFromJson(Map<String, dynamic> json) =>
    CancelOrderResponse(
      message: json['message'] as String,
      orderId: (json['orderId'] as num).toInt(),
    );

Map<String, dynamic> _$CancelOrderResponseToJson(
  CancelOrderResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'orderId': instance.orderId,
};

PublicTrackingResponse _$PublicTrackingResponseFromJson(
  Map<String, dynamic> json,
) => PublicTrackingResponse(
  orderId: (json['orderId'] as num).toInt(),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  history: (json['history'] as List<dynamic>)
      .map((e) => OrderTracking.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PublicTrackingResponseToJson(
  PublicTrackingResponse instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'history': instance.history,
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
