import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/helpers/app_helpers.dart';
import 'package:sweetylust/utils/order_utils.dart';
import 'package:sweetylust/widgets/app_widgets.dart';
import 'package:sweetylust/services/toast_service.dart';
import '../providers/providers.dart';
import '../models/order_model.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(orderNotifierProvider.notifier).fetchOrders();
    } catch (e) {
      if (mounted) {
        ToastService.error(
          context,
          'Error',
          description: 'No se pudieron cargar las órdenes',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderNotifierProvider);
    final orders = orderState.orders;

    ref.listen<OrderState>(orderNotifierProvider, (previous, next) {
      if (next.error != null &&
          next.error!.isNotEmpty &&
          next.error != previous?.error) {
        if (mounted) {
          ToastService.error(context, 'Error', description: next.error!);
          ref.read(orderNotifierProvider.notifier).clearError();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context, 'Mis Pedidos'),
      body: SafeArea(
        child: _isLoading || orderState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : orders.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tienes pedidos',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '¡Realiza tu primera compra!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  ...orders.map((order) => _buildOrderCard(context, order)),
                ],
              ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final isCancelled = order.status.toLowerCase() == 'cancelado';
    final statusColor = OrderUtils.getStatusColor(order.status);
    final statusDisplay = OrderUtils.getStatusDisplayName(order.status);
    final orderNumber = order.id.toString().padLeft(4, '0');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: order.id),
          ),
        ).then((_) => _loadOrders());
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #$orderNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Colors.white, thickness: 2),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(order.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} artículo${order.items.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
