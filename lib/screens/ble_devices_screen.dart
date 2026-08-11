import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sweetylust/providers/permission_provider.dart';
import 'package:sweetylust/services/ble_service.dart';
import 'package:sweetylust/widgets/app_widgets.dart';

class BleDevicesScreen extends ConsumerStatefulWidget {
  const BleDevicesScreen({super.key});

  @override
  ConsumerState<BleDevicesScreen> createState() => _BleDevicesScreenState();
}

class _BleDevicesScreenState extends ConsumerState<BleDevicesScreen> {
  final BLEService _bleService = BLEService();

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<BluetoothDevice?>? _deviceSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  bool _isScanning = false;
  bool _isConnected = false;
  String? _connectedDeviceName;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    _initializeBLE();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _deviceSubscription?.cancel();
    _scanResultsSubscription?.cancel();

    _bleService.stopScan();

    super.dispose();
  }

  Future<void> _initializeBLE() async {
    final permissionNotifier = ref.read(permissionNotifierProvider.notifier);
    await permissionNotifier.checkPermissions();

    final hasPermission = ref
        .read(permissionNotifierProvider)
        .hasBluetoothPermission;
    if (!hasPermission) {
      await permissionNotifier.requestBluetooth();
    }

    await _bleService.initialize();

    _connectionSubscription = _bleService.connectionState.listen(
      (state) {
        if (!mounted) return;
        setState(() {
          _isConnected = state == BluetoothConnectionState.connected;
          if (state == BluetoothConnectionState.connected) {
            _isScanning = false;
          }
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isConnected = false;
          _isScanning = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $error')));
      },
    );

    _deviceSubscription = _bleService.connectedDevice.listen((device) {
      if (!mounted) return;
      setState(() {
        _connectedDeviceName = device?.platformName ?? device?.name;
      });
    });

    _scanResultsSubscription = _bleService.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _scanResults = results;
        _isScanning = _bleService.isScanning;
      });
    });

    if (_bleService.isConnected) {
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _connectedDeviceName =
            _bleService.device?.platformName ?? _bleService.device?.name;
      });
    }

    if (!_isConnected) {
      _startScan();
    }
  }

  Future<void> _startScan() async {
    final hasPermission = ref
        .read(permissionNotifierProvider)
        .hasBluetoothPermission;
    if (!hasPermission) {
      final granted = await ref
          .read(permissionNotifierProvider.notifier)
          .requestBluetooth();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se necesitan permisos de Bluetooth')),
        );
        return;
      }
    }

    final isEnabled = await FlutterBluePlus.isOn;
    if (!isEnabled) {
      final permissionService = ref.read(permissionServiceProvider);
      final shouldOpen = await permissionService.showBluetoothEnableDialog(
        context,
      );
      if (shouldOpen) {
        await FlutterBluePlus.turnOn();
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    try {
      await _bleService.startScan(timeout: const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al escanear: $e')));
    }
  }

  Future<void> _stopScan() async {
    await _bleService.stopScan();
    if (!mounted) return;
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnected) return;

    if (!mounted) return;
    setState(() {
      _isScanning = false;
    });

    final success = await _bleService.connectToDevice(device);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isConnected = true;
        _connectedDeviceName = device.platformName.isNotEmpty
            ? device.platformName
            : device.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Conectado a ${device.platformName.isNotEmpty ? device.platformName : device.name}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al conectar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnectDevice() async {
    await _bleService.disconnectDevice();
    if (!mounted) return;
    setState(() {
      _isConnected = false;
      _connectedDeviceName = null;
      _isScanning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Desconectado'),
        backgroundColor: Colors.orange,
      ),
    );

    _startScan();
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(permissionNotifierProvider);
    final scanResults = _bleService.scanResultsList;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context, 'Vincular Dispositivo'),
      body: SafeArea(
        child: Column(
          children: [
            if (!permissionState.hasBluetoothPermission)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se necesitan permisos de Bluetooth',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(permissionNotifierProvider.notifier)
                          .requestBluetooth(),
                      child: const Text('Solicitar'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    _isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_searching,
                    size: 60,
                    color: _isConnected
                        ? Colors.green
                        : const Color(0xFFFFA8A8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isConnected
                        ? 'Dispositivo conectado'
                        : 'Dispositivos cercanos',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isConnected)
                    Text(
                      _connectedDeviceName ?? 'Conectado',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  Text(
                    _isConnected
                        ? 'Tu dispositivo está vinculado correctamente'
                        : 'Asegúrate de que tu dispositivo esté encendido y cerca.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  if (_isScanning && !_isConnected)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Buscando dispositivos...'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  if (_isConnected)
                    _buildDeviceCard(
                      _connectedDeviceName ?? 'Dispositivo',
                      'Conectado',
                      true,
                      onTap: _disconnectDevice,
                    )
                  else if (_isScanning && scanResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Buscando dispositivos...',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...scanResults.map((result) {
                      final device = result.device;
                      if (device.platformName.isEmpty)
                        return const SizedBox.shrink();
                      return _buildDeviceCard(
                        device.platformName,
                        'Toca para vincular',
                        false,
                        onTap: () => _connectToDevice(device),
                      );
                    }),
                  if (!_isConnected && scanResults.isEmpty && !_isScanning)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No se encontraron dispositivos\nToca "Buscar de nuevo" para escanear',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            if (!_isConnected)
              buildBottomButton(
                _isScanning ? 'ESCANEANDO...' : 'BUSCAR DE NUEVO',
                Icons.refresh,
                _isScanning ? _stopScan : _startScan,
              ),
            if (_isConnected)
              buildBottomButton(
                'DESCONECTAR',
                Icons.bluetooth_disabled,
                _disconnectDevice,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    String name,
    String status,
    bool isConnected, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isConnected ? Colors.green.shade50 : const Color(0xFFF2F2F5),
          borderRadius: BorderRadius.circular(12.0),
          border: isConnected ? Border.all(color: Colors.green) : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.watch_outlined,
              color: isConnected ? Colors.green : const Color(0xFFFFA8A8),
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: isConnected ? Colors.green : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (!isConnected) const Icon(Icons.link, color: Colors.black87),
            if (isConnected)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
