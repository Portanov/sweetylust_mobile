import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/widgets/app_widgets.dart';
import 'package:sweetylust/services/toast_service.dart';
import '../providers/providers.dart';
import '../models/address_model.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  final Address? address;

  const AddAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _recipientPhoneController =
      TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _extNumberController = TextEditingController();
  final TextEditingController _intNumberController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _referencesController = TextEditingController();

  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _loadAddressData();
    }
  }

  void _loadAddressData() {
    final address = widget.address!;
    _recipientNameController.text = address.recipientName;
    _recipientPhoneController.text = address.recipientPhone;
    _streetController.text = address.street;
    _extNumberController.text = address.extNumber;
    if (address.intNumber != null) {
      _intNumberController.text = address.intNumber!;
    }
    _neighborhoodController.text = address.neighborhood;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _postalCodeController.text = address.postalCode;
    if (address.references != null) {
      _referencesController.text = address.references!;
    }
    _isDefault = address.isDefault;
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _streetController.dispose();
    _extNumberController.dispose();
    _intNumberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _referencesController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CreateAddressRequest(
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _recipientPhoneController.text.trim(),
        street: _streetController.text.trim(),
        extNumber: _extNumberController.text.trim(),
        intNumber: _intNumberController.text.trim().isEmpty
            ? null
            : _intNumberController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        references: _referencesController.text.trim().isEmpty
            ? null
            : _referencesController.text.trim(),
        isDefault: _isDefault,
      );

      final notifier = ref.read(addressNotifierProvider.notifier);
      bool success;

      if (widget.address != null) {
        final updateRequest = UpdateAddressRequest(
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
          street: _streetController.text.trim(),
          extNumber: _extNumberController.text.trim(),
          intNumber: _intNumberController.text.trim().isEmpty
              ? null
              : _intNumberController.text.trim(),
          neighborhood: _neighborhoodController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          references: _referencesController.text.trim().isEmpty
              ? null
              : _referencesController.text.trim(),
          isDefault: _isDefault,
        );
        success = await notifier.updateAddress(
          widget.address!.id,
          updateRequest,
        );
      } else {
        success = await notifier.createAddress(request);
      }

      setState(() => _isLoading = false);

      if (success && mounted) {
        ToastService.success(
          context,
          widget.address != null ? 'Actualizada' : 'Creada',
          description: widget.address != null
              ? 'Dirección actualizada correctamente'
              : 'Dirección creada correctamente',
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ToastService.error(
          context,
          'Error',
          description: widget.address != null
              ? 'No se pudo actualizar la dirección'
              : 'No se pudo crear la dirección',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastService.error(context, 'Error', description: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(
        context,
        isEditing ? 'Editar Dirección' : 'Nueva Dirección',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInputLabel('Nombre del destinatario'),
                      buildTextField(
                        controller: _recipientNameController,
                        hint: 'Ej. María García',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      buildInputLabel('Teléfono'),
                      buildTextField(
                        controller: _recipientPhoneController,
                        hint: '5512345678',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El teléfono es requerido';
                          }
                          if (value.length != 10) {
                            return 'Deben ser 10 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      buildInputLabel('Calle'),
                      buildTextField(
                        controller: _streetController,
                        hint: 'Calle Principal',
                        icon: Icons.streetview,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La calle es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildInputLabel('Número exterior'),
                                buildTextField(
                                  controller: _extNumberController,
                                  hint: '123',
                                  icon: Icons.numbers,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requerido';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildInputLabel('Número interior'),
                                buildTextField(
                                  controller: _intNumberController,
                                  hint: 'A',
                                  icon: Icons.numbers,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      buildInputLabel('Colonia'),
                      buildTextField(
                        controller: _neighborhoodController,
                        hint: 'Colonia Centro',
                        icon: Icons.location_city,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La colonia es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildInputLabel('Ciudad'),
                                buildTextField(
                                  controller: _cityController,
                                  hint: 'Ciudad',
                                  icon: Icons.location_city,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requerido';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildInputLabel('Estado'),
                                buildTextField(
                                  controller: _stateController,
                                  hint: 'Estado',
                                  icon: Icons.location_city,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requerido';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      buildInputLabel('Código Postal'),
                      buildTextField(
                        controller: _postalCodeController,
                        hint: '76000',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El código postal es requerido';
                          }
                          if (value.length != 5) {
                            return 'Deben ser 5 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      buildInputLabel('Referencias (opcional)'),
                      buildTextField(
                        controller: _referencesController,
                        hint: 'Frente al parque, entre calles...',
                        icon: Icons.note_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Checkbox(
                            value: _isDefault,
                            onChanged: (value) {
                              setState(() {
                                _isDefault = value ?? false;
                              });
                            },
                            activeColor: Colors.black,
                          ),
                          const Text(
                            'Establecer como predeterminada',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            buildBottomButton(
              isEditing ? 'ACTUALIZAR DIRECCIÓN' : 'GUARDAR DIRECCIÓN',
              Icons.save_outlined,
              _isLoading ? null : _saveAddress,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
