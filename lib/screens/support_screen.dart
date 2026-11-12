import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sweetylust/models/report_model.dart';
import 'package:sweetylust/providers/report_provider.dart';
import 'package:sweetylust/services/toast_service.dart';
import 'package:sweetylust/widgets/app_widgets.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^\+?[0-9\s()-]{7,20}$').hasMatch(value.trim())) {
      return 'Ingresa un teléfono válido';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final request = CreateReportRequest(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
    );

    final created = await ref
        .read(reportNotifierProvider.notifier)
        .createReport(request);

    if (!mounted) return;

    if (!created) {
      final error = ref.read(reportNotifierProvider).error;
      ToastService.error(
        context,
        'No se pudo enviar',
        description: error ?? 'Intenta nuevamente más tarde.',
      );
      return;
    }

    ToastService.success(
      context,
      'Reporte enviado',
      description: 'Gracias por ayudarnos a mejorar SweetyLust.',
    );
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _subjectController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(reportNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context, 'Soporte'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿NECESITAS AYUDA?',
                        style: GoogleFonts.alumniSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cuéntanos qué ocurrió y nuestro equipo revisará tu reporte.',
                        style: GoogleFonts.poiretOne(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      buildInputLabel('Nombre'),
                      buildTextField(
                        controller: _nameController,
                        hint: 'Tu nombre',
                        icon: Icons.person_outline,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'El nombre es requerido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      buildInputLabel('Correo electrónico'),
                      buildTextField(
                        controller: _emailController,
                        hint: 'correo@ejemplo.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      buildInputLabel('Teléfono (opcional)'),
                      buildTextField(
                        controller: _phoneController,
                        hint: '5512345678',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      buildInputLabel('Asunto'),
                      buildTextField(
                        controller: _subjectController,
                        hint: 'Describe brevemente el problema',
                        icon: Icons.subject_outlined,
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El asunto es requerido';
                          }
                          if (value.trim().length > 100) {
                            return 'Máximo 100 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      buildInputLabel('Mensaje'),
                      buildTextField(
                        controller: _messageController,
                        hint: 'Cuéntanos qué sucedió...',
                        icon: Icons.chat_bubble_outline,
                        maxLines: 5,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'El mensaje es requerido'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            buildBottomButton(
              'ENVIAR REPORTE',
              Icons.send_outlined,
              isLoading ? null : _submit,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
