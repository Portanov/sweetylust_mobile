import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:sweetylust/helpers/app_helpers.dart';
import 'package:sweetylust/screens/login_screen.dart';
import 'package:sweetylust/providers/providers.dart';
import 'package:sweetylust/models/auth_model.dart';
import 'package:sweetylust/widgets/app_widgets.dart';
import 'package:toastification/toastification.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _obscurePassword = true;
  String? _dateError;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
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
        _dateController.text = "$day/$month/${pickedDate.year}";

        if (age < 18) {
          _dateError = "Debes ser mayor de 18 años para registrarte.";
        } else {
          _dateError = null;
        }
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateError != null) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.custom('Alert', Colors.deepOrange, Icons.error),
        title: Text('Alerta'),
        description: RichText(text: TextSpan(text: 'Debes ser mayor de 18 años para registrarte.'))
      );
      return;
    }

    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona tu fecha de nacimiento.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final birthDateFormatted = formatDateForAPI(_dateController.text);

      final phoneInt = int.tryParse(_phoneController.text.trim()) ?? 0;

      final request = RegisterRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: phoneInt,
        birthDate: birthDateFormatted,
      );

      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.register(request);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.success,
          title: Text('Éxito'),
          description: RichText(
            text: TextSpan(
              text: '¡Registro exitoso! Inicia sesión para continuar.',
            ),
          ),
          autoCloseDuration: const Duration(seconds: 3),
          dragToClose: true,
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      toastification.show(
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        title: Text('Error'),
        description: RichText(
          text: TextSpan(text: 'Error al registrarse: ${e.toString()}'),
        ),
        autoCloseDuration: const Duration(seconds: 3),
        dragToClose: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(authProvider.notifier).clearError();
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
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Únete a SweetyLust para comenzar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 30),

                        buildInputLabel('Nombre de usuario'),
                        buildTextField(
                          controller: _usernameController,
                          hint: 'mi_usuario',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El nombre de usuario es requerido';
                            }
                            if (value.length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        buildInputLabel('Correo electrónico'),
                        buildTextField(
                          controller: _emailController,
                          hint: 'tucorreo@ejemplo.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El correo es requerido';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        buildInputLabel('Contraseña'),
                        buildTextField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La contraseña es requerida';
                            }
                            if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        buildInputLabel('Teléfono (10 dígitos)'),
                        buildTextField(
                          controller: _phoneController,
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
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Solo números';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        buildInputLabel('Fecha de nacimiento'),
                        buildTextField(
                          controller: _dateController,
                          hint: 'dd/mm/aaaa',
                          icon: Icons.cake_outlined,
                          isDate: true,
                          readOnly: true,
                          onTap: () => _pickDate(context),
                          errorText: _dateError,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona tu fecha de nacimiento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),

                        SizedBox(
                          height: 56.5,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF232323),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'REGISTRARSE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        const Spacer(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿Ya tienes cuenta?',
                              style: TextStyle(fontWeight: FontWeight.w300),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Inicia sesión',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
