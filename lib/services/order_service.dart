import '../models/order_model.dart';
import 'base_service.dart';

class OrderService extends BaseService {
  OrderService({required super.httpClient, required super.apiUrl});

  @override
  String get basePath => '/orders';

  Future<List<Order>> getMyOrders() {
    return getList<Order>('/my', fromJson: (json) => Order.fromJson(json));
  }

  Future<OrderResponse> getMyOrderDetail(int orderId) {
    return get<OrderResponse>(
      '/my/$orderId',
      fromJson: (json) => OrderResponse.fromJson(json),
    );
  }

  Future<CancelOrderResponse> cancelOrder(int orderId) {
    return patch<CancelOrderResponse>(
      '/my/$orderId/cancel',
      fromJson: (json) => CancelOrderResponse.fromJson(json),
      body: {},
    );
  }

  Future<PublicTrackingResponse> getPublicTracking(int orderId) {
    return get<PublicTrackingResponse>(
      '/$orderId/tracking',
      fromJson: (json) => PublicTrackingResponse.fromJson(json),
    );
  }
}
