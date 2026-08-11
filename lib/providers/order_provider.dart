import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'service_providers.dart';

class OrderState {
  final List<Order> orders;
  final Order? currentOrder;
  final OrderResponse? orderDetail;
  final bool isLoading;
  final String? error;
  final String? filterStatus;

  OrderState({
    this.orders = const [],
    this.currentOrder,
    this.orderDetail,
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });

  OrderState copyWith({
    List<Order>? orders,
    Order? currentOrder,
    OrderResponse? orderDetail,
    bool? isLoading,
    String? error,
    String? filterStatus,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      currentOrder: currentOrder ?? this.currentOrder,
      orderDetail: orderDetail ?? this.orderDetail,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  List<Order> get filteredOrders {
    if (filterStatus == null || filterStatus!.isEmpty) return orders;
    return orders
        .where(
          (order) => order.status.toLowerCase() == filterStatus!.toLowerCase(),
        )
        .toList();
  }

  Map<String, int> get orderCountByStatus {
    final counts = <String, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return counts;
  }

  factory OrderState.initial() => OrderState();
  factory OrderState.loading() => OrderState(isLoading: true);
  factory OrderState.error(String message) => OrderState(error: message);
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderService _service;

  OrderNotifier(this._service) : super(OrderState.initial());

  Future<void> fetchOrders() async {
    state = OrderState.loading();

    try {
      final orders = await _service.getMyOrders();
      state = OrderState(orders: orders, isLoading: false);
    } catch (e) {
      state = OrderState.error(e.toString());
    }
  }

  Future<void> fetchOrderDetail(int orderId) async {
    state = OrderState.loading();

    try {
      final orderDetail = await _service.getMyOrderDetail(orderId);

      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(
            id: orderDetail.id,
            status: orderDetail.status,
            total: orderDetail.total,
            createdAt: orderDetail.createdAt,
            address: orderDetail.address,
            items: orderDetail.items,
            tracking: orderDetail.tracking,
          );
        }
        return order;
      }).toList();

      state = OrderState(
        orders: updatedOrders,
        orderDetail: orderDetail,
        currentOrder: updatedOrders.cast<Order?>().firstWhere(
          (order) => order?.id == orderId,
          orElse: () => null,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = OrderState.error(e.toString());
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      final response = await _service.cancelOrder(orderId);

      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(status: 'Cancelado');
        }
        return order;
      }).toList();

      state = OrderState(
        orders: updatedOrders,
        orderDetail:
            state.orderDetail != null && state.orderDetail!.id == orderId
            ? state.orderDetail!.copyWith(status: 'Cancelado')
            : state.orderDetail,
        currentOrder: state.currentOrder?.id == orderId
            ? state.currentOrder!.copyWith(status: 'Cancelado')
            : state.currentOrder,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = OrderState.error(e.toString());
      return false;
    }
  }

  Future<PublicTrackingResponse?> getPublicTracking(int orderId) async {
    try {
      return await _service.getPublicTracking(orderId);
    } catch (e) {
      state = OrderState.error(e.toString());
      return null;
    }
  }

  void filterByStatus(String? status) {
    state = state.copyWith(filterStatus: status);
  }

  void clearFilter() {
    state = state.copyWith(filterStatus: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateOrderStatus(int orderId, String newStatus) {
    final updatedOrders = state.orders.map((order) {
      if (order.id == orderId) {
        return order.copyWith(status: newStatus);
      }
      return order;
    }).toList();

    state = OrderState(
      orders: updatedOrders,
      orderDetail: state.orderDetail != null && state.orderDetail!.id == orderId
          ? state.orderDetail!.copyWith(status: newStatus)
          : state.orderDetail,
      currentOrder: state.currentOrder?.id == orderId
          ? state.currentOrder!.copyWith(status: newStatus)
          : state.currentOrder,
      filterStatus: state.filterStatus,
      isLoading: state.isLoading,
      error: state.error,
    );
  }
}

final orderNotifierProvider = StateNotifierProvider<OrderNotifier, OrderState>((
  ref,
) {
  final service = ref.watch(orderServiceProvider);
  return OrderNotifier(service);
});

final ordersProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderNotifierProvider).orders;
});

final filteredOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderNotifierProvider).filteredOrders;
});

final orderDetailProvider = Provider<OrderResponse?>((ref) {
  return ref.watch(orderNotifierProvider).orderDetail;
});

final orderCountByStatusProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(orderNotifierProvider).orderCountByStatus;
});

final ordersListProvider = FutureProvider<List<Order>>((ref) async {
  final notifier = ref.watch(orderNotifierProvider.notifier);
  await notifier.fetchOrders();
  return ref.watch(orderNotifierProvider).orders;
});

final ordersByStatusProvider = Provider.family<List<Order>, String>((
  ref,
  status,
) {
  final orders = ref.watch(ordersProvider);
  return orders
      .where((order) => order.status.toLowerCase() == status.toLowerCase())
      .toList();
});

final orderByIdProvider = Provider.family<Order?, int>((ref, orderId) {
  final orders = ref.watch(ordersProvider);
  try {
    return orders.firstWhere((order) => order.id == orderId);
  } catch (_) {
    return null;
  }
});
