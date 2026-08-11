// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TVInitResponse _$TVInitResponseFromJson(Map<String, dynamic> json) =>
    TVInitResponse(
      qrData: json['qrData'] as String,
      roomId: json['roomId'] as String,
      connectionCode: json['connectionCode'] as String,
    );

Map<String, dynamic> _$TVInitResponseToJson(TVInitResponse instance) =>
    <String, dynamic>{
      'qrData': instance.qrData,
      'roomId': instance.roomId,
      'connectionCode': instance.connectionCode,
    };

QRScanSuccess _$QRScanSuccessFromJson(Map<String, dynamic> json) =>
    QRScanSuccess(
      message: json['message'] as String,
      roomId: json['roomId'] as String,
      tvDeviceId: json['tvDeviceId'] as String,
    );

Map<String, dynamic> _$QRScanSuccessToJson(QRScanSuccess instance) =>
    <String, dynamic>{
      'message': instance.message,
      'roomId': instance.roomId,
      'tvDeviceId': instance.tvDeviceId,
    };

OrderScannedEvent _$OrderScannedEventFromJson(Map<String, dynamic> json) =>
    OrderScannedEvent(
      orderBarcode: json['orderBarcode'] as String,
      scannedBy: json['scannedBy'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$OrderScannedEventToJson(OrderScannedEvent instance) =>
    <String, dynamic>{
      'orderBarcode': instance.orderBarcode,
      'scannedBy': instance.scannedBy,
      'timestamp': instance.timestamp,
    };

OrderProductsResponse _$OrderProductsResponseFromJson(
  Map<String, dynamic> json,
) => OrderProductsResponse(
  products: (json['products'] as List<dynamic>)
      .map((e) => OrderItemWS.fromJson(e as Map<String, dynamic>))
      .toList(),
  timestamp: json['timestamp'] as String,
);

Map<String, dynamic> _$OrderProductsResponseToJson(
  OrderProductsResponse instance,
) => <String, dynamic>{
  'products': instance.products,
  'timestamp': instance.timestamp,
};

OrderItemWS _$OrderItemWSFromJson(Map<String, dynamic> json) => OrderItemWS(
  id: (json['id'] as num).toInt(),
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: json['unit_price'] as String,
  subtotal: json['subtotal'] as String,
  product: ProductWS.fromJson(json['product'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderItemWSToJson(OrderItemWS instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'subtotal': instance.subtotal,
      'product': instance.product,
    };

ProductWS _$ProductWSFromJson(Map<String, dynamic> json) => ProductWS(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  image: json['image'] as String,
  price: json['price'] as String,
  stock: (json['stock'] as num).toInt(),
  category: json['category'] as String,
);

Map<String, dynamic> _$ProductWSToJson(ProductWS instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'image': instance.image,
  'price': instance.price,
  'stock': instance.stock,
  'category': instance.category,
};
