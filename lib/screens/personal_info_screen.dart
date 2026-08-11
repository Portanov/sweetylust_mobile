import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:sweetylust/helpers/app_helpers.dart';
import 'package:sweetylust/services/toast_service.dart';
import 'package:sweetylust/widgets/app_widgets.dart';
import '../providers/providers.dart';
import '../models/user_model.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isInitialLoading = true);

    try {
      final userNotifier = ref.read(userNotifierProvider.notifier);
      await userNotifier.fetchProfile();
      final userState = ref.read(userNotifierProvider);
      final user = userState.user;

      if (user != null && mounted) {
        setState(() {
          _usernameController.text = user.username;
          _emailController.text = user.email;
          _phoneController.text = user.phone.toString();
          if (user.birthDate.isNotEmpty) {
            _birthDateController.text = formatDateForDisplay(user.birthDate);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(
          context,
          'Error',
          description: 'No se pudieron cargar los datos',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  void _pickDate(BuildContext context) async {
    DateTime? pickedDate = await DatePicker.showSimpleDatePicker(
      context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      dateFormat: "dd-MMMM-yyyy",
      locale: DateTimePickerLocale.es,
      looping: true,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      pickerMode: DateTimePickerMode.date,
    );

    if (pickedDate != null) {
      int age = DateTime.now().year - pickedDate.year;
      if (DateTime.now().month < pickedDate.month ||
          (DateTime.now().month == pickedDate.month &&
              DateTime.now().day < pickedDate.day)) {
        age--;
      }

      setState(() {
        final day = pickedDate.day.toString().padLeft(2, '0');
        final month = pickedDate.month.toString().padLeft(2, '0');
        _birthDateController.text = "$day/$month/${pickedDate.year}";

        if (age < 18) {
          _dateError = "Debes ser mayor de 18 años.";
        } else {
          _dateError = null;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_usernameController.text.isEmpty) {
      ToastService.error(
        context,
        'Error',
        description: 'El nombre de usuario es requerido',
      );
      return;
    }

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ToastService.error(
        context,
        'Error',
        description: 'Ingresa un correo válido',
      );
      return;
    }

    if (_phoneController.text.length != 10) {
      ToastService.error(
        context,
        'Error',
        description: 'El teléfono debe tener 10 dígitos',
      );
      return;
    }

    if (_birthDateController.text.isEmpty) {
      ToastService.error(
        context,
        'Error',
        description: 'Selecciona tu fecha de nacimiento',
      );
      return;
    }

    if (_dateError != null) {
      ToastService.error(context, 'Error', description: _dateError!);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = UpdateProfileRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: int.tryParse(_phoneController.text.trim()) ?? 0,
        birthDate: formatDateForAPI(_birthDateController.text),
      );

      await ref.read(userNotifierProvider.notifier).updateProfile(request);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ToastService.error(context, 'Error', description: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserState>(userNotifierProvider, (previous, next) {
      print(
        '📢 Listener llamado - previous: ${previous?.isUpdated}, next: ${next.isUpdated}',
      );

      // ✅ Cuando se actualiza correctamente
      if (next.isUpdated && !(previous?.isUpdated ?? false)) {
        print('✅ Detected update success!');
        if (mounted) {
          ToastService.success(
            context,
            'Éxito',
            description: 'Datos actualizados correctamente',
          );
        }
        _loadUserData();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(userNotifierProvider.notifier).resetUpdated();
          }
        });
      }

      // ✅ Manejar errores
      if (next.error != null &&
          next.error!.isNotEmpty &&
          next.error != previous?.error) {
        print('❌ Error detected: ${next.error}');
        if (mounted) {
          ToastService.error(context, 'Error', description: next.error!);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(userNotifierProvider.notifier).clearError();
          }
        });
      }
    });
    
    final userState = ref.watch(userNotifierProvider);
    final isLoading = userState.isLoading || _isLoading;

    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Información Personal',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Información Personal',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
                    buildInputLabel('Nombre de usuario'),
                    buildTextField(
                      controller: _usernameController,
                      hint: 'Tu nombre de usuario',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),

                    buildInputLabel('Correo electrónico'),
                    buildTextField(
                      controller: _emailController,
                      hint: 'tu@correo.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    buildInputLabel('Teléfono (10 dígitos)'),
                    buildTextField(
                      controller: _phoneController,
                      hint: '5512345678',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    buildInputLabel('Fecha de nacimiento'),
                    buildTextField(
                      controller: _birthDateController,
                      hint: 'dd/mm/aaaa',
                      icon: Icons.cake_outlined,
                      readOnly: true,
                      onTap: () => _pickDate(context),
                      errorText: _dateError,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Debes ser mayor de 18 años',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            buildBottomButton(
              'GUARDAR CAMBIOS',
              Icons.save_outlined,
              _saveChanges,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
