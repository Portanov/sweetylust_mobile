import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/ble_admin_service.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late final BleClient _client;
  late WorkMetricsData _data;

  StreamSubscription<WorkMetricsData>? _dataSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  List<ScanResult> _scanResults = const [];
  bool _connected = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _errorMessage;
  String? _connectingDeviceId;
  bool _goalSnackShown = false;
  bool _serviceReady = false;

  @override
  void initState() {
    super.initState();
    _client = BleClient();
    _data = _client.currentData;

    _dataSub = _client.dataStream.listen((data) {
      if (!mounted) return;

      setState(() {
        _data = data;
        _connected = _client.isConnected;
        _serviceReady = true;
      });

      if (data.goalReached && !_goalSnackShown) {
        _goalSnackShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta del día completada'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!data.goalReached) {
        _goalSnackShown = false;
      }
    });

    _scanSub = _client.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _scanResults = results;
      });
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _scanSub?.cancel();
    _client.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _errorMessage = null;
      _isScanning = true;
      _scanResults = const [];
    });

    try {
      await _client.startScan();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _errorMessage = null;
      _isConnecting = true;
      _connectingDeviceId = device.remoteId.toString();
    });

    try {
      await _client.connectToDevice(device);
      if (mounted) {
        setState(() {
          _connected = _client.isConnected;
          _serviceReady = _client.isConnected;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDeviceId = null;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await _client.disconnect();
    if (!mounted) return;

    setState(() {
      _connected = false;
      _isScanning = false;
      _errorMessage = null;
      _serviceReady = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1020),
        foregroundColor: Colors.white,
        title: const Text('Monitor de operaciones'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _connected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_searching,
            ),
            color: _connected ? Colors.greenAccent : Colors.lightBlueAccent,
            onPressed: _isConnecting
                ? null
                : (_connected ? _disconnect : _startScan),
          ),
        ],
      ),
      body: SafeArea(
        child: _connected ? _buildMetricsView() : _buildDiscoveryView(),
      ),
    );
  }

  Widget _buildDiscoveryView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.bluetooth_searching,
                  color: Colors.lightBlueAccent,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Selecciona un wearable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isScanning
                      ? 'Buscando dispositivos BLE cercanos...'
                      : 'Escanea y toca el dispositivo para conectarte.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning || _isConnecting ? null : _startScan,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _isScanning ? 'Escaneando...' : 'Buscar dispositivos',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(child: _buildDeviceList()),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_isScanning && _scanResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.lightBlueAccent),
      );
    }

    if (_scanResults.isEmpty) {
      return const Center(
        child: Text(
          'No hay dispositivos encontrados todavía.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: _scanResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;
        final id = device.remoteId.toString();
        final isConnectingThis = _connectingDeviceId == id;

        final deviceName = device.platformName.isNotEmpty
            ? device.platformName
            : (result.advertisementData.advName.isNotEmpty
                  ? result.advertisementData.advName
                  : 'Wearable BLE');

        return Material(
          color: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(
              Icons.watch_outlined,
              color: Colors.lightBlueAccent,
            ),
            title: Text(
              deviceName,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(id, style: const TextStyle(color: Colors.white54)),
            trailing: isConnectingThis
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: _isConnecting ? null : () => _connectToDevice(device),
          ),
        );
      },
    );
  }

  Widget _buildMetricsView() {
    final data = _data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!_serviceReady)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent),
              ),
              child: const Text(
                'Conectado al wearable. Inicializando lectura de metricas...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: data.goalReached
                  ? Colors.green.withValues(alpha: 0.18)
                  : const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: data.goalReached
                    ? Colors.greenAccent
                    : Colors.blueAccent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.employeeName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: data.goalReached
                        ? Colors.greenAccent
                        : Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: data.dailyGoal == 0
                      ? 0
                      : (data.packedOrders / data.dailyGoal).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.white24,
                  color: data.goalReached
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.packedOrders}/${data.dailyGoal} paquetes',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              MetricCard(
                label: 'Horas trabajadas',
                value: data.hoursWorked.toStringAsFixed(1),
                unit: 'h',
                color: Colors.indigoAccent,
                icon: Icons.access_time,
              ),
              MetricCard(
                label: 'Empacados',
                value: '${data.packedOrders}',
                unit: 'paquetes',
                color: Colors.orangeAccent,
                icon: Icons.inventory_2_outlined,
              ),
              MetricCard(
                label: 'Pedidos enviados',
                value: '${data.shippedOrders}',
                unit: 'envíos',
                color: Colors.greenAccent,
                icon: Icons.local_shipping,
              ),
              MetricCard(
                label: 'Meta diaria',
                value: '${data.dailyGoal}',
                unit: 'objetivo',
                color: data.goalReached
                    ? Colors.greenAccent
                    : Colors.purpleAccent,
                icon: Icons.flag,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
