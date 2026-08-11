import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/widgets/app_widgets.dart';
import 'package:sweetylust/services/toast_service.dart';
import '../providers/providers.dart';
import '../models/order_model.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetail();
    });
  }

  Future<void> _loadOrderDetail() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(orderNotifierProvider.notifier)
          .fetchOrderDetail(widget.orderId);
    } catch (e) {
      if (mounted) {
        ToastService.error(
          context,
          'Error',
          description: 'No se pudo cargar el detalle de la orden',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text(
          '¿Estás seguro de que quieres cancelar este pedido?\n\n'
          'Una vez cancelado no se podrá revertir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir con el pedido'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isCancelling = true);
      try {
        final success = await ref
            .read(orderNotifierProvider.notifier)
            .cancelOrder(widget.orderId);

        if (success && mounted) {
          ToastService.success(
            context,
            'Cancelado',
            description: 'El pedido ha sido cancelado correctamente',
          );
          await _loadOrderDetail();
        } else if (mounted) {
          ToastService.error(
            context,
            'Error',
            description: 'No se pudo cancelar el pedido',
          );
        }
      } catch (e) {
        if (mounted) {
          ToastService.error(context, 'Error', description: e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isCancelling = false);
        }
      }
    }
  }

  bool _canCancelOrder(String status) {
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'procesando' || lowerStatus == 'confirmado';
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'procesando':
        return 'Procesando';
      case 'confirmado':
        return 'Confirmado';
      case 'enviado':
        return 'Enviado';
      case 'en_camino':
        return 'En camino';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'procesando':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'enviado':
        return Colors.purple;
      case 'en_camino':
        return Colors.indigo;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderNotifierProvider);

    final Order? order = orderState.orderDetail != null
        ? Order(
            id: orderState.orderDetail!.id,
            status: orderState.orderDetail!.status,
            total: orderState.orderDetail!.total,
            createdAt: orderState.orderDetail!.createdAt,
            address: orderState.orderDetail!.address,
            items: orderState.orderDetail!.items,
            tracking: orderState.orderDetail!.tracking,
          )
        : orderState.currentOrder;

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
      appBar: buildAppBar(
        context,
        'Pedido #${widget.orderId.toString().padLeft(4, '0')}',
      ),
      body: _isLoading || orderState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? const Center(child: Text('Orden no encontrada'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estado del pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusDisplayName(order.status),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(order.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F5),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(children: [..._buildTimeline(order)]),
                    ),
                    const SizedBox(height: 32),

                    if (_canCancelOrder(order.status))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isCancelling ? null : _cancelOrder,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isCancelling
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Text(
                                    'CANCELAR PEDIDO',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                    if (_canCancelOrder(order.status))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Puedes cancelar tu pedido mientras esté en estado "Procesando" o "Confirmado".',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    Text(
                      'Artículos (${order.items.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildProductItem(item),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (order.address != null) ...[
                      const Text(
                        'Dirección de envío',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F5),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF344054),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.address!.recipientName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tel: ${order.address!.recipientPhone}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.address!.street} ${order.address!.extNumber}${order.address!.intNumber != null ? ' Int ${order.address!.intNumber}' : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  Text(
                                    '${order.address!.neighborhood}, ${order.address!.city}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  Text(
                                    '${order.address!.state}, CP ${order.address!.postalCode}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    const Text(
                      'Resumen de pago',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCostRow(
                      'Subtotal',
                      '\$${order.total.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildCostRow('Envío', '\$0.00'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    ),
                    _buildCostRow(
                      'Total pagado',
                      '\$${order.total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildTimeline(Order order) {
    final List<OrderTracking> trackingList = order.tracking ?? [];

    if (trackingList.isEmpty) {
      return [
        _buildTimelineStep(
          _getStatusDisplayName(order.status),
          _formatDate(order.createdAt),
          true,
          isFirst: true,
          isLast: true,
        ),
      ];
    }

    final sortedTracking = List<OrderTracking>.from(trackingList)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final List<Widget> steps = [];
    for (int i = 0; i < sortedTracking.length; i++) {
      final track = sortedTracking[i];
      final isLast = i == sortedTracking.length - 1;
      steps.add(
        _buildTimelineStep(
          track.note,
          _formatDate(track.createdAt),
          true,
          isFirst: i == 0,
          isLast: isLast,
        ),
      );
    }
    return steps;
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    bool isCompleted, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green.shade600 : Colors.grey.shade400,
              size: 24,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted
                    ? Colors.green.shade600
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                    color: isCompleted ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(OrderItem item) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F5),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: item.product.image.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    item.product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
                )
              : const Icon(Icons.image_outlined, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Cant: ${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${item.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w300,
            color: Colors.black87,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
