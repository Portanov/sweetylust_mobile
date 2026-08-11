import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ble_constants.dart';

class WorkMetricsData {
  final String employeeName;
  final double hoursWorked;
  final int packedOrders;
  final int shippedOrders;
  final int dailyGoal;
  final bool goalReached;
  final String statusMessage;
  final DateTime timestamp;

  const WorkMetricsData({
    required this.employeeName,
    required this.hoursWorked,
    required this.packedOrders,
    required this.shippedOrders,
    required this.dailyGoal,
    required this.goalReached,
    required this.statusMessage,
    required this.timestamp,
  });

  WorkMetricsData copyWith({
    String? employeeName,
    double? hoursWorked,
    int? packedOrders,
    int? shippedOrders,
    int? dailyGoal,
    bool? goalReached,
    String? statusMessage,
    DateTime? timestamp,
  }) {
    return WorkMetricsData(
      employeeName: employeeName ?? this.employeeName,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      packedOrders: packedOrders ?? this.packedOrders,
      shippedOrders: shippedOrders ?? this.shippedOrders,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      goalReached: goalReached ?? this.goalReached,
      statusMessage: statusMessage ?? this.statusMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class BleClient {
  BluetoothDevice? _device;

  final List<StreamSubscription> _subs = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  final StreamController<WorkMetricsData> _dataCtrl =
      StreamController<WorkMetricsData>.broadcast();
  final StreamController<List<ScanResult>> _scanResultsCtrl =
      StreamController<List<ScanResult>>.broadcast();

  Stream<WorkMetricsData> get dataStream => _dataCtrl.stream;
  Stream<List<ScanResult>> get scanResults => _scanResultsCtrl.stream;

  bool _connected = false;
  bool get isConnected => _connected;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResultsList => _scanResults;

  WorkMetricsData _current = WorkMetricsData(
    employeeName: 'Empleado',
    hoursWorked: 0,
    packedOrders: 0,
    shippedOrders: 0,
    dailyGoal: 50,
    goalReached: false,
    statusMessage: 'Sin datos',
    timestamp: DateTime.now(),
  );

  WorkMetricsData get currentData => _current;

  Future<void> startScan() async {
    await _ensureCentralPermissions();

    if (_isScanning) return;

    _scanResults = [];
    _scanResultsCtrl.add(const []);
    await _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final byId = <String, ScanResult>{};

      for (final result in results) {
        final advertisedUUIDs = result.advertisementData.serviceUuids.map(
          (u) => u.toString().toLowerCase(),
        );

        final matchesService = advertisedUUIDs.contains(
          BleConstants.serviceUUID.toLowerCase(),
        );

        if (!matchesService) continue;

        final key = result.device.remoteId.toString();
        byId[key] = result;
      }

      _scanResults = byId.values.toList();
      _scanResultsCtrl.add(_scanResults);
    });

    _isScanning = true;

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [Guid(BleConstants.serviceUUID)],
      );

      await FlutterBluePlus.isScanning.where((value) => value == false).first;
    } finally {
      _isScanning = false;
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();

    if (_connected &&
        _device?.remoteId.toString() == device.remoteId.toString()) {
      return;
    }

    await disconnect();
    _device = device;
    await _connect();
  }

  Future<void> _connect() async {
    final device = _device;
    if (device == null) {
      throw Exception('No hay dispositivo seleccionado');
    }

    await _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      _connected = state == BluetoothConnectionState.connected;

      if (state == BluetoothConnectionState.disconnected) {
        _connected = false;
      }
    });

    try {
      await device.connect(
        license: License.nonprofit,
        autoConnect: false,
        mtu: 23,
        timeout: const Duration(seconds: 20),
      );

      _connected = true;
      unawaited(_discoverAndSubscribe());
    } catch (e) {
      _connected = false;
      try {
        await device.disconnect();
      } catch (_) {}
      throw Exception(
        'No se pudo conectar al wearable. Verifica que esté encendido, desbloqueado y no conectado a otra app.',
      );
    }
  }

  Future<void> _discoverAndSubscribe() async {
    final device = _device;
    if (device == null) return;

    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();

    final services = await device.discoverServices();
    var serviceFound = false;

    for (final svc in services) {
      if (svc.uuid.toString().toLowerCase() !=
          BleConstants.serviceUUID.toLowerCase()) {
        continue;
      }

      serviceFound = true;
      debugPrint('[BleClient] Servicio encontrado: ${svc.uuid}');

      for (final char in svc.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();
        debugPrint(
          '[BleClient] Caracteristica detectada: $uuid '
          'notify=${char.properties.notify} '
          'indicate=${char.properties.indicate} '
          'read=${char.properties.read}',
        );

        if (char.properties.notify || char.properties.indicate) {
          await char.setNotifyValue(true);
          debugPrint('[BleClient] Suscripcion activada para $uuid');
        }

        final sub = char.lastValueStream.listen((bytes) {
          _handleValue(uuid, bytes);
        });
        _subs.add(sub);

        if (char.properties.read) {
          try {
            final bytes = await char.read();
            _handleValue(uuid, bytes);
          } catch (_) {}
        }
      }
    }

    if (!serviceFound) {
      throw Exception('El dispositivo no expone el servicio esperado');
    }

    _dataCtrl.add(_current.copyWith(timestamp: DateTime.now()));
  }

  void _handleValue(String uuid, List<int> bytes) {
    if (bytes.isEmpty) return;

    try {
      debugPrint('[BleClient] RX $uuid len=${bytes.length} bytes=$bytes');

      if (uuid == BleConstants.hoursWorkedUUID.toLowerCase()) {
        if (bytes.length < 4) {
          debugPrint(
            '[BleClient] hoursWorked ignorado: se esperaban 4 bytes y llegaron ${bytes.length}',
          );
          return;
        }
        final bd = ByteData.sublistView(Uint8List.fromList(bytes));
        final hours = bd.getInt32(0, Endian.little) / 10;
        _current = _current.copyWith(hoursWorked: hours);
        debugPrint('[BleClient] hoursWorked parseado: $hours');
      } else if (uuid == BleConstants.packedOrdersUUID.toLowerCase()) {
        if (bytes.length < 4) {
          debugPrint(
            '[BleClient] packedOrders ignorado: se esperaban 4 bytes y llegaron ${bytes.length}',
          );
          return;
        }
        final bd = ByteData.sublistView(Uint8List.fromList(bytes));
        _current = _current.copyWith(
          packedOrders: bd.getInt32(0, Endian.little),
        );
        debugPrint(
          '[BleClient] packedOrders parseado: ${_current.packedOrders}',
        );
      } else if (uuid == BleConstants.shippedOrdersUUID.toLowerCase()) {
        if (bytes.length < 4) {
          debugPrint(
            '[BleClient] shippedOrders ignorado: se esperaban 4 bytes y llegaron ${bytes.length}',
          );
          return;
        }
        final bd = ByteData.sublistView(Uint8List.fromList(bytes));
        _current = _current.copyWith(
          shippedOrders: bd.getInt32(0, Endian.little),
        );
        debugPrint(
          '[BleClient] shippedOrders parseado: ${_current.shippedOrders}',
        );
      } else if (uuid == BleConstants.dailyGoalUUID.toLowerCase()) {
        if (bytes.length < 4) {
          debugPrint(
            '[BleClient] dailyGoal ignorado: se esperaban 4 bytes y llegaron ${bytes.length}',
          );
          return;
        }
        final bd = ByteData.sublistView(Uint8List.fromList(bytes));
        _current = _current.copyWith(dailyGoal: bd.getInt32(0, Endian.little));
        debugPrint('[BleClient] dailyGoal parseado: ${_current.dailyGoal}');
      } else if (uuid == BleConstants.statusUUID.toLowerCase()) {
        _current = _current.copyWith(
          statusMessage: utf8.decode(bytes, allowMalformed: true),
        );
        debugPrint('[BleClient] status parseado: ${_current.statusMessage}');
      } else {
        debugPrint('[BleClient] UUID no mapeado: $uuid bytes=$bytes');
      }

      _current = _current.copyWith(
        goalReached: _current.packedOrders >= _current.dailyGoal,
        timestamp: DateTime.now(),
      );

      _dataCtrl.add(_current);
    } catch (e) {
      debugPrint('[BleClient] Error parseando $uuid bytes=$bytes error=$e');
    }
  }

  Future<void> disconnect() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();

    await _connectionSub?.cancel();
    _connectionSub = null;

    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _connected = false;
  }

  void dispose() {
    unawaited(disconnect());
    unawaited(_scanSub?.cancel());
    _dataCtrl.close();
    _scanResultsCtrl.close();
  }

  Future<void> _ensureCentralPermissions() async {
    if (!Platform.isAndroid) return;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final denied = statuses.entries
        .where((e) => !e.value.isGranted)
        .map((e) => e.key.toString())
        .toList();

    if (denied.isNotEmpty) {
      throw Exception('Permisos BLE faltantes: ${denied.join(', ')}');
    }
  }
}
