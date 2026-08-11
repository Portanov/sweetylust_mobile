import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/screens/add_addresses_screen.dart';
import 'package:sweetylust/widgets/app_widgets.dart';
import 'package:sweetylust/services/toast_service.dart';
import '../providers/providers.dart';
import '../models/address_model.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(addressNotifierProvider.notifier).fetchAddresses();
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Error', description: 'No se pudieron cargar las direcciones');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAddress(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: const Text('¿Estás seguro de que quieres eliminar esta dirección?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(addressNotifierProvider.notifier).deleteAddress(id);
      if (success && mounted) {
        ToastService.success(context, 'Eliminada', description: 'Dirección eliminada correctamente');
      } else if (mounted) {
        ToastService.error(context, 'Error', description: 'No se pudo eliminar la dirección');
      }
    }
  }

  Future<void> _setDefaultAddress(int id) async {
    final success = await ref.read(addressNotifierProvider.notifier).setDefaultAddress(id);
    if (success && mounted) {
      ToastService.success(context, 'Actualizada', description: 'Dirección predeterminada actualizada');
    } else if (mounted) {
      ToastService.error(context, 'Error', description: 'No se pudo actualizar la dirección');
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressNotifierProvider);
    final addresses = addressState.addresses;

    // Escuchar errores
    ref.listen<AddressState>(addressNotifierProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty && next.error != previous?.error) {
        if (mounted) {
          ToastService.error(context, 'Error', description: next.error!);
          ref.read(addressNotifierProvider.notifier).clearError();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context, 'Mis Direcciones'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading || addressState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : addresses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tienes direcciones guardadas',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Agrega tu primera dirección',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(20.0),
                          children: [
                            ...addresses.map((address) => _buildAddressCard(
                              address: address,
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddAddressScreen(
                                      address: address,
                                    ),
                                  ),
                                ).then((_) => _loadAddresses());
                              },
                              onDelete: () => _deleteAddress(address.id),
                              onSetDefault: () => _setDefaultAddress(address.id),
                            )),
                          ],
                        ),
            ),
            buildBottomButton(
              'AGREGAR NUEVA DIRECCIÓN',
              Icons.add_location_alt_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAddressScreen(),
                  ),
                ).then((_) => _loadAddresses());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required Address address,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onSetDefault,
  }) {
    final addressText = '${address.street} ${address.extNumber}${address.intNumber != null ? ' Int ${address.intNumber}' : ''}\n'
        '${address.neighborhood}, ${address.city}\n'
        '${address.state}, CP ${address.postalCode}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F5),
        borderRadius: BorderRadius.circular(16.0),
        border: address.isDefault
            ? Border.all(color: const Color(0xFF232323), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: address.isDefault ? Colors.black : Colors.black54,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.recipientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Predet.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  addressText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!address.isDefault)
                      IconButton.outlined(
                        onPressed: onSetDefault,
                        icon: Icon(Icons.star),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: Colors.black54,
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}