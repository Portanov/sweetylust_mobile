// lib/screens/admin/qr_scan_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sweetylust/providers/admin_shell_provider.dart';
import 'package:sweetylust/providers/providers.dart';
import 'package:sweetylust/providers/websocket_provider.dart';
import 'package:sweetylust/screens/login_screen.dart';
import 'package:sweetylust/services/websocket_service.dart' as ws_service;

class QRScanScreen extends ConsumerStatefulWidget {
  const QRScanScreen({super.key});

  @override
  ConsumerState<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends ConsumerState<QRScanScreen> {
  bool _isScanning = true;
  bool _isCheckingPermission = true;
  bool _hasCameraPermission = false;
  bool _isLoggingOut = false;
  String? _errorMessage;
  String? _permissionMessage;
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketServiceProvider).connect();
      _requestCameraPermission();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    ref.read(webSocketServiceProvider).disconnect();
    ref.read(adminTabIndexProvider.notifier).state = 0;
    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wsService = ref.watch(webSocketServiceProvider);
    final isConnected = ref.watch(wsIsConnectedProvider);
    final roomId = ref.watch(wsRoomIdProvider);
    final mobileStatus = ref.watch(wsMobileStatusProvider);
    ref.listen(wsIsConnectedProvider, (previous, next) {
      if (next == true) {
        setState(() {
          _errorMessage = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Conectar a TV'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isLoggingOut ? null : _handleLogout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout, color: Colors.white, size: 18),
            label: Text(
              _isLoggingOut ? 'Saliendo...' : 'Salir',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de conexión
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Sala', roomId.isEmpty ? '---' : roomId),
                _buildInfoItem('Móvil', mobileStatus),
                _buildInfoItem(
                  'Estado',
                  isConnected ? 'Conectado' : 'Desconectado',
                ),
              ],
            ),
          ),

          // Escáner QR
          Expanded(
            child: _isCheckingPermission
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Solicitando permisos de cámara...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : !_hasCameraPermission
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 72,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Se necesita permiso de cámara para escanear',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          if (_permissionMessage != null)
                            Text(
                              _permissionMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _requestCameraPermission,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Permitir cámara'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              await openAppSettings();
                            },
                            child: const Text('Abrir Ajustes'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _isScanning
                ? MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final String? code = barcode.rawValue;
                        if (code != null && code.isNotEmpty) {
                          _handleQRCode(code, wsService);
                          break;
                        }
                      }
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.green[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '¡Conectado a la TV!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sala: $roomId',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(adminTabIndexProvider.notifier).state = 1;
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Ir a Empacar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Mensaje de error
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[900],
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Botones de control
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isScanning) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isScanning = false;
                      });
                      _scannerController.stop();
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Detener'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isScanning = true;
                        _errorMessage = null;
                      });
                      _scannerController.start();
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Reiniciar Escáner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    wsService.disconnect();
                    wsService.connect();
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reconectar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _requestCameraPermission() async {
    if (!mounted) return;
    setState(() {
      _isCheckingPermission = true;
      _permissionMessage = null;
    });

    final status = await Permission.camera.status;
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _hasCameraPermission = true;
        _isCheckingPermission = false;
      });
      return;
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        _hasCameraPermission = false;
        _isCheckingPermission = false;
        _permissionMessage =
            'El permiso de cámara está bloqueado. Actívalo en Ajustes.';
      });
      return;
    }

    final result = await Permission.camera.request();
    if (!mounted) return;

    setState(() {
      _hasCameraPermission = result.isGranted;
      _isCheckingPermission = false;
      _permissionMessage = result.isGranted
          ? null
          : 'No se concedió el permiso de cámara.';
    });
  }

  void _handleQRCode(String code, ws_service.WebSocketService wsService) {
    final qrPayload = _extractQrPayload(code);

    setState(() {
      _isScanning = false;
    });

    _scannerController.stop();
    wsService.scanTVQR(qrPayload);

    StreamSubscription<String>? subscription;
    subscription = wsService.onError.listen((error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error;
        _isScanning = true;
      });
      _scannerController.start();
      subscription?.cancel();
    });

    StreamSubscription<bool>? mobileSub;
    mobileSub = wsService.onMobileConnected.listen((connected) {
      if (connected) {
        if (!mounted) return;
        setState(() {
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Conectado a la TV exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      mobileSub?.cancel();
    });
  }

  String _extractQrPayload(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return code;

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final qrData = map['qrCode']?.toString();
          if (qrData != null && qrData.isNotEmpty) {
            return qrData;
          }
          final roomId = map['roomId']?.toString();
          if (roomId != null && roomId.isNotEmpty) {
            return roomId;
          }
        }
      } catch (_) {
        // Si no es JSON válido, continúa con heurísticas simples.
      }
    }

    final roomMatch = RegExp(r'roomId=([^&]+)').firstMatch(trimmed);
    if (roomMatch != null) {
      return Uri.decodeComponent(roomMatch.group(1)!);
    }

    return trimmed;
  }
}
