import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sweetylust/models/websocket_model.dart';
import 'package:sweetylust/providers/admin_shell_provider.dart';
import 'package:sweetylust/providers/websocket_provider.dart';
import 'package:sweetylust/services/websocket_service.dart' as ws_service;

class PackingScreen extends ConsumerStatefulWidget {
  const PackingScreen({super.key});

  @override
  ConsumerState<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends ConsumerState<PackingScreen>
    with WidgetsBindingObserver {
  bool _isScanning = true;
  bool _isPacking = false;
  bool _isCheckingPermission = true;
  bool _hasCameraPermission = false;
  bool _isFinishing = false;
  bool _isScannerRunning = false;
  String? _errorMessage;
  String? _lastScannedOrder;
  String? _permissionMessage;
  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.code39],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsService = ref.read(webSocketServiceProvider);
      if (!wsService.isSocketConnected) {
        wsService.connect();
      }
      _requestCameraPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isPackingTabActive = ref.read(adminTabIndexProvider) == 1;
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncScannerState(isTabActive: isPackingTabActive));
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_stopScannerIfNeeded());
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(adminTabIndexProvider);
    final isPackingTabActive = currentTabIndex == 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncScannerState(isTabActive: isPackingTabActive));
    });

    final wsService = ref.watch(webSocketServiceProvider);
    final isConnected = ref.watch(wsIsConnectedProvider);
    final roomId = ref.watch(wsRoomIdProvider);
    final mobileStatus = ref.watch(wsMobileStatusProvider);
    final products = ref.watch(wsProductsProvider);
    final currentOrder = ref.watch(wsCurrentOrderProvider);
    final connectionStatus = ref.watch(wsConnectionStatusProvider);

    ref.listen(wsProductsProvider, (previous, next) {
      if (next.isNotEmpty) {
        setState(() {
          _isPacking = true;
          _errorMessage = null;
        });
        unawaited(_stopScannerIfNeeded());
      }
    });

    ref.listen(wsIsOrderCompletedProvider, (previous, next) {
      if (next == true) {
        setState(() {
          _isFinishing = false;
          _isPacking = false;
          _isScanning = true;
          _lastScannedOrder = null;
        });
        unawaited(_syncScannerState(isTabActive: isPackingTabActive));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Orden empacada completamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    ref.listen(wsErrorStreamProvider, (previous, next) {
      next.whenData((error) {
        setState(() {
          _isFinishing = false;
          _errorMessage = error;
        });
      });
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Empacar Orden'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(adminTabIndexProvider.notifier).state = 0;
          },
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(connectionStatus, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de conexión
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Sala', roomId.isEmpty ? '---' : roomId),
                _buildInfoItem('Móvil', mobileStatus),
                _buildInfoItem(
                  'Orden',
                  currentOrder.isEmpty ? '---' : '#$currentOrder',
                ),
                _buildInfoItem('Productos', products.length.toString()),
              ],
            ),
          ),

          // Si hay productos, mostrarlos
          if (products.isNotEmpty)
            Expanded(flex: 1, child: _buildProductsList(products)),

          // Escáner de código de barras o botón finalizar
          Expanded(
            flex: products.isEmpty ? 2 : 1,
            child: _isPacking && products.isNotEmpty
                ? _buildFinishPackingButton(wsService)
                : _buildBarcodeScanner(wsService),
          ),

          // Mensaje de error
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProductsList(List<OrderItemWS> products) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos de la orden:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.product.image.isNotEmpty
                          ? Image.network(
                              item.product.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[800],
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                    title: Text(
                      item.product.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'SKU: ${item.product.id}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${item.unitPrice}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeScanner(ws_service.WebSocketService wsService) {
    if (_isCheckingPermission) {
      return const Center(
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
      );
    }

    if (!_hasCameraPermission) {
      return Center(
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
      );
    }

    if (!_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Productos cargados!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Presiona "Finalizar Empacado" para completar',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isFinishing
                  ? null
                  : () {
                      final orderToFinish =
                          (_lastScannedOrder != null &&
                              _lastScannedOrder!.isNotEmpty)
                          ? _lastScannedOrder!
                          : wsService.cleanOrderBarcode(
                              ref.read(wsCurrentOrderProvider),
                            );

                      if (orderToFinish.isEmpty) {
                        setState(() {
                          _errorMessage =
                              'No hay una orden válida para finalizar.';
                        });
                        return;
                      }

                      setState(() {
                        _isFinishing = true;
                        _errorMessage = null;
                      });
                      wsService.finishPacking(orderBarcode: orderToFinish);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
              ),
              child: _isFinishing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      '✅ Finalizar Empacado',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _isScanning = true;
                  _isPacking = false;
                });
                unawaited(
                  _syncScannerState(
                    isTabActive: ref.read(adminTabIndexProvider) == 1,
                  ),
                );
              },
              child: const Text('Escáner de nuevo'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  _handleBarcode(code, wsService);
                  break;
                }
              }
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[900],
          child: const Text(
            'Escanea el código de barras de la orden',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFinishPackingButton(ws_service.WebSocketService wsService) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_lastScannedOrder != null)
            Text(
              'Orden: #$_lastScannedOrder',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isFinishing
                ? null
                : () {
                    _showFinishPackingDialog(context, wsService);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[400],
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 60),
            ),
            child: _isFinishing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    '✅ Finalizar Empacado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isScanning = true;
                _isPacking = false;
                _lastScannedOrder = null;
              });
              unawaited(
                _syncScannerState(
                  isTabActive: ref.read(adminTabIndexProvider) == 1,
                ),
              );
            },
            child: const Text(
              'Escáner de nuevo',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
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
      final isPackingTabActive = ref.read(adminTabIndexProvider) == 1;
      unawaited(_syncScannerState(isTabActive: isPackingTabActive));
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

    final isPackingTabActive = ref.read(adminTabIndexProvider) == 1;
    unawaited(_syncScannerState(isTabActive: isPackingTabActive));
  }

  void _handleBarcode(String code, ws_service.WebSocketService wsService) {
    final cleanedCode = wsService.cleanOrderBarcode(code);

    setState(() {
      _isScanning = false;
      _lastScannedOrder = cleanedCode;
    });

    unawaited(_stopScannerIfNeeded());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Orden #$cleanedCode escaneada'),
        backgroundColor: Colors.blue,
      ),
    );

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

    wsService.scanOrder(cleanedCode);
  }

  void _showFinishPackingDialog(
    BuildContext context,
    ws_service.WebSocketService wsService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Finalizar empacado?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que quieres finalizar el empacado de esta orden?',
            ),
            const SizedBox(height: 12),
            Text(
              'Orden: #${_lastScannedOrder ?? 'N/A'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final orderToFinish =
                  (_lastScannedOrder != null && _lastScannedOrder!.isNotEmpty)
                  ? _lastScannedOrder!
                  : wsService.cleanOrderBarcode(
                      ref.read(wsCurrentOrderProvider),
                    );

              if (orderToFinish.isEmpty) {
                setState(() {
                  _errorMessage = 'No hay una orden válida para finalizar.';
                });
                Navigator.pop(dialogContext);
                return;
              }

              Navigator.pop(dialogContext);
              setState(() {
                _isFinishing = true;
                _errorMessage = null;
              });
              wsService.finishPacking(orderBarcode: orderToFinish);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[400]),
            child: const Text(
              '✅ Sí, finalizar',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncScannerState({required bool isTabActive}) async {
    final shouldRun =
        isTabActive &&
        !_isCheckingPermission &&
        _hasCameraPermission &&
        _isScanning &&
        !_isPacking &&
        !_isFinishing;

    if (shouldRun) {
      await _startScannerIfNeeded();
      return;
    }

    await _stopScannerIfNeeded();
  }

  Future<void> _startScannerIfNeeded() async {
    if (_isScannerRunning) return;
    try {
      await _scannerController.start();
      _isScannerRunning = true;
    } catch (_) {
      // Ignorado: algunos dispositivos lanzan excepción si el preview no está listo.
    }
  }

  Future<void> _stopScannerIfNeeded() async {
    if (!_isScannerRunning) return;
    try {
      await _scannerController.stop();
    } catch (_) {
      // Ignorado: evitar crashear por estados intermedios de cámara.
    }
    _isScannerRunning = false;
  }
}
