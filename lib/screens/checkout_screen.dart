import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/models/cart_model.dart';
import 'package:sweetylust/screens/order_success_screen.dart';
import 'package:sweetylust/widgets/checkout_widgets.dart';
import 'package:toastification/toastification.dart';
import '../providers/providers.dart';
import '../models/address_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  Address? _selectedAddress;
  bool _isProcessing = false;
  bool _paymentCompleted = false;
  String? _errorMessage;
  int? _orderId;

  bool _errorShown = false;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _errorShown = false;
    _isCanceling = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  @override
  void dispose() {
    _errorShown = false;
    _isCanceling = false;
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final addressNotifier = ref.read(addressNotifierProvider.notifier);
    await addressNotifier.fetchAddresses();

    final state = ref.read(addressNotifierProvider);
    if (state.addresses.isNotEmpty) {
      setState(() {
        _selectedAddress = state.defaultAddress ?? state.addresses.first;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_selectedAddress == null) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.info,
        title: Text('Aviso'),
        description: RichText(
          text: TextSpan(text: 'Selecciona una dirección de envío'),
        ),
        autoCloseDuration: const Duration(seconds: 3),
        dragToClose: true,
      );
      return;
    }

    final cartState = ref.read(cartNotifierProvider);
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

     setState(() {
      _isProcessing = true;
      _paymentCompleted = false;
      _errorMessage = null;
      _orderId = null;
      _errorShown = false;
      _isCanceling = false;
    });

    try {
      final response = await ref
          .read(cartNotifierProvider.notifier)
          .checkoutWithPaymentSheet(_selectedAddress!.id);

      setState(() {
        _isProcessing = false;
        _paymentCompleted = response != null;
        if (response != null) {
          _orderId = response.id;
        }
      });

      if (response != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(order: response),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _paymentCompleted = false;
      });

      String errorMessage = 'Error en el pago';
      bool isCanceled = false;

      if (e.toString().contains('cancelado') ||
          e.toString().contains('Canceled') ||
          e.toString().contains('canceled')) {
        errorMessage = 'Pago cancelado por el usuario';
        isCanceled = true;
        setState(() {
          _isCanceling = true;
        });
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      setState(() {
        _errorMessage = errorMessage;
      });

      if (!_errorShown && mounted && !isCanceled) {
        _errorShown = true;
        ScaffoldMessenger.of(context).clearSnackBars();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text('Error'),
          description: RichText(text: TextSpan(text: errorMessage)),
          autoCloseDuration: const Duration(seconds: 3),
          dragToClose: true,
        );
      }

      if (isCanceled && mounted && !_errorShown) {
        _errorShown = true;
        ScaffoldMessenger.of(context).clearSnackBars();
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          title: Text('Cancelado'),
          icon: const Icon(Icons.cancel_outlined),
          primaryColor: Colors.black87,
          foregroundColor: Colors.grey.shade900,
          backgroundColor: Colors.grey,
          description: RichText(text: TextSpan(text: 'Has cancelado el pago')),
          autoCloseDuration: const Duration(seconds: 2),
          dragToClose: true
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressNotifierProvider);
    final cartState = ref.watch(cartNotifierProvider);
    final addresses = addressState.addresses;
    final total = cartState.total;
    final itemCount = cartState.itemCount;

    ref.listen<CartState>(cartNotifierProvider, (previous, next) {
      if (next.error != null &&
          next.error!.isNotEmpty &&
          next.error != previous?.error &&
          !_isCanceling &&
          mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        Future.microtask(() {
          if (mounted) {
            ref.read(cartNotifierProvider.notifier).clearError();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Resumen del pedido',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección de envío',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (addressState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (addresses.isEmpty)
                      buildEmptyAddress(context)
                    else
                      _buildAddressSelector(addresses),

                    const SizedBox(height: 32),

                    const Text(
                      'Resumen del pedido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildOrderSummary(cartState.items, itemCount),

                    const SizedBox(height: 24),

                    const Text(
                      'Desglose de costos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCostRow(
                      'Subtotal ($itemCount artículos)',
                      '\$${total.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _buildCostRow('Costo de envío', '\$0.00'),
                    if (total > 0) ...[
                      const SizedBox(height: 12),
                      _buildCostRow('Descuento', '-\$0.00', isDiscount: true),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    ),

                    _buildCostRow(
                      'Total a pagar',
                      '\$${total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Pago seguro a través de Stripe',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Image.network(
                            'https://stripe.com/img/v3/home/twitter.png',
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text(
                                'Stripe',
                                style: TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null && !_isCanceling)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_paymentCompleted)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '¡Pedido confirmado exitosamente!',
                            style: TextStyle(color: Colors.green, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 56.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF232323),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed:
                          (_isProcessing ||
                              _paymentCompleted ||
                              addresses.isEmpty)
                          ? null
                          : _processPayment,
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'PROCESANDO PAGO...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'PAGAR AHORA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.payment_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSelector(List<Address> addresses) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F5),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<Address>(
            initialValue: _selectedAddress,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'Selecciona una dirección',
            ),
            items: addresses.map((address) {
              return DropdownMenuItem(
                value: address,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.recipientName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Predet.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${address.street} ${address.extNumber}${address.intNumber != null ? ' Int ${address.intNumber}' : ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      '${address.neighborhood}, ${address.city}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedAddress = value);
            },
          ),

          if (_selectedAddress != null) ...[
            const Divider(),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF344054),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAddress!.recipientName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tel: ${_selectedAddress!.recipientPhone}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${_selectedAddress!.street} ${_selectedAddress!.extNumber}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (_selectedAddress!.intNumber != null)
                        Text(
                          'Int: ${_selectedAddress!.intNumber}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      Text(
                        '${_selectedAddress!.neighborhood}, ${_selectedAddress!.city}, ${_selectedAddress!.state}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'CP ${_selectedAddress!.postalCode}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (_selectedAddress!.references != null)
                        Text(
                          'Ref: ${_selectedAddress!.references}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary(List<CartItem> items, int itemCount) {
    if (items.isEmpty) {
      return const Text('No hay productos en el carrito');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ...items.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.title} x${item.quantity}',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${items.length - 3} productos más',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCostRow(
    String label,
    String amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w300,
            color: Colors.black87,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 22 : 15,
            fontWeight: isTotal
                ? FontWeight.w900
                : (isDiscount ? FontWeight.w600 : FontWeight.w400),
            color: isDiscount ? const Color(0xFFFFA8A8) : Colors.black,
          ),
        ),
      ],
    );
  }
}
