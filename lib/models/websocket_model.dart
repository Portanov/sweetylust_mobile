import 'package:json_annotation/json_annotation.dart';

part 'websocket_model.g.dart';

@JsonSerializable()
class TVInitResponse {
  final String qrData;
  final String roomId;
  final String connectionCode;

  TVInitResponse({
    required this.qrData,
    required this.roomId,
    required this.connectionCode,
  });

  factory TVInitResponse.fromJson(Map<String, dynamic> json) =>
      _$TVInitResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TVInitResponseToJson(this);
}

@JsonSerializable()
class QRScanSuccess {
  final String message;
  final String roomId;
  final String tvDeviceId;

  QRScanSuccess({
    required this.message,
    required this.roomId,
    required this.tvDeviceId,
  });

  factory QRScanSuccess.fromJson(Map<String, dynamic> json) =>
      _$QRScanSuccessFromJson(json);
  Map<String, dynamic> toJson() => _$QRScanSuccessToJson(this);
}

@JsonSerializable()
class OrderScannedEvent {
  final String orderBarcode;
  final String scannedBy;
  final String timestamp;

  OrderScannedEvent({
    required this.orderBarcode,
    required this.scannedBy,
    required this.timestamp,
  });

  factory OrderScannedEvent.fromJson(Map<String, dynamic> json) =>
      _$OrderScannedEventFromJson(json);
  Map<String, dynamic> toJson() => _$OrderScannedEventToJson(this);
}

@JsonSerializable()
class OrderProductsResponse {
  final List<OrderItemWS> products;
  final String timestamp;

  OrderProductsResponse({required this.products, required this.timestamp});

  factory OrderProductsResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderProductsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OrderProductsResponseToJson(this);
}

@JsonSerializable()
class OrderItemWS {
  final int id;
  final int quantity;
  @JsonKey(name: 'unit_price')
  final String unitPrice;
  final String subtotal;
  final ProductWS product;

  OrderItemWS({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.product,
  });

  factory OrderItemWS.fromJson(Map<String, dynamic> json) =>
      _$OrderItemWSFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemWSToJson(this);
}

@JsonSerializable()
class ProductWS {
  final int id;
  final String title;
  final String description;
  final String image;
  final String price;
  final int stock;
  final String category;

  ProductWS({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    required this.stock,
    required this.category,
  });

  factory ProductWS.fromJson(Map<String, dynamic> json) =>
      _$ProductWSFromJson(json);
  Map<String, dynamic> toJson() => _$ProductWSToJson(this);
}
