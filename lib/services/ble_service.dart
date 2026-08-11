import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  final _deviceController = StreamController<BluetoothDevice?>.broadcast();
  final _batteryLevelController = StreamController<int>.broadcast();
  final _heartRateController = StreamController<int>.broadcast();
  final _stepsController = StreamController<int>.broadcast();

  BluetoothDevice? _connectedDevice;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isInitialized = false;
  bool _isConnecting = false;

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  Timer? _reconnectionTimer;

  static const int MAX_RECONNECTION_ATTEMPTS = 5;
  int _reconnectionAttempts = 0;

  VoidCallback? onDeviceConnected;
  VoidCallback? onDeviceDisconnected;

  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;
  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<BluetoothDevice?> get connectedDevice => _deviceController.stream;
  Stream<int> get batteryLevel => _batteryLevelController.stream;
  Stream<int> get heartRate => _heartRateController.stream;
  Stream<int> get steps => _stepsController.stream;

  List<ScanResult> get scanResultsList => _scanResults;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null;
  bool get isConnecting => _isConnecting;
  BluetoothDevice? get device => _connectedDevice;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        await _checkPermissions();
      }

      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 2));
      }

      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        debugPrint('📡 Estado del adaptador: $state');
        if (state == BluetoothAdapterState.off) {
          _handleBluetoothOff();
        } else if (state == BluetoothAdapterState.on) {
          _handleBluetoothOn();
        }
      });

      FlutterBluePlus.scanResults.listen((results) {
        final filteredResults = results
            .where((r) => r.device.platformName.isNotEmpty)
            .toList();

        _scanResults = filteredResults;
        _scanResultsController.add(filteredResults);
      });

      await _restoreConnection();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing BLE: $e');
      rethrow;
    }
  }

  Future<void> _restoreConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString('ble_connected_device_id');
      final savedDeviceName = prefs.getString('ble_connected_device_name');
      final isConnected = prefs.getBool('ble_is_connected') ?? false;

      if (savedDeviceId != null && savedDeviceName != null && isConnected) {
        final devices = await FlutterBluePlus.scanResults.first;
        BluetoothDevice? foundDevice;

        for (var result in devices) {
          if (result.device.remoteId.toString() == savedDeviceId) {
            foundDevice = result.device;
            break;
          }
        }

        if (foundDevice != null) {
          await connectToDevice(foundDevice);
        } else {
          await startScan(timeout: const Duration(seconds: 5));

          for (var result in _scanResults) {
            if (result.device.remoteId.toString() == savedDeviceId) {
              await connectToDevice(result.device);
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring connection: $e');
    }
  }

  Future<void> _saveConnectedDevice(BluetoothDevice device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ble_connected_device_id',
        device.remoteId.toString(),
      );
      await prefs.setString('ble_connected_device_name', device.platformName);
      await prefs.setBool('ble_is_connected', true);
      await prefs.setString(
        'ble_connected_at',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error saving device: $e');
    }
  }

  Future<void> _clearSavedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ble_connected_device_id');
      await prefs.remove('ble_connected_device_name');
      await prefs.remove('ble_is_connected');
      await prefs.remove('ble_connected_at');
    } catch (e) {
      debugPrint('Error clearing saved device: $e');
    }
  }

  Future<bool> hasSavedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('ble_connected_device_id');
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String>?> getSavedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('ble_connected_device_id');
      final name = prefs.getString('ble_connected_device_name');
      if (id != null && name != null) {
        return {'id': id, 'name': name};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _handleBluetoothOff() {
    if (_connectedDevice != null) {
      _connectedDevice = null;
      _deviceController.add(null);
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      onDeviceDisconnected?.call();
    }
    _isConnecting = false;
    _reconnectionTimer?.cancel();
  }

  void _handleBluetoothOn() {
    _restoreConnection();
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_isScanning) return;

    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        throw Exception('Permisos de Bluetooth no concedidos');
      }

      final isEnabled = await FlutterBluePlus.isOn;
      if (!isEnabled) {
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 2));

        if (!await FlutterBluePlus.isOn) {
          throw Exception('Bluetooth no se pudo activar');
        }
      }

      _isScanning = true;
      _scanResults.clear();

      await FlutterBluePlus.startScan(timeout: timeout, withServices: []);

      await FlutterBluePlus.isScanning
          .where((scanning) => scanning == false)
          .first;

      _isScanning = false;
    } catch (e) {
      _isScanning = false;
      debugPrint('Error scanning: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      debugPrint('Scan stopped');
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) {
      return false;
    }

    try {
      if (_connectedDevice != null) {
        await disconnectDevice();
      }

      _isConnecting = true;
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        debugPrint('📡 Estado de conexión: $state');
        _connectionStateController.add(state);

        if (state == BluetoothConnectionState.connected) {
          _connectedDevice = device;
          _deviceController.add(device);
          _isConnecting = false;
          _reconnectionAttempts = 0;
          _saveConnectedDevice(device);
          onDeviceConnected?.call();
        } else if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _deviceController.add(null);
          _isConnecting = false;
          _clearSavedDevice();
          onDeviceDisconnected?.call();
          _scheduleReconnection(device);
        }
      });

      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 20),
        autoConnect: false,
      );
      await device.discoverServices();
      await _setupNotifications(device);
      return true;
    } catch (e) {
      _connectedDevice = null;
      _deviceController.add(null);
      _connectionSubscription?.cancel();
      _isConnecting = false;
      _clearSavedDevice();
      return false;
    }
  }

  Future<void> _setupNotifications(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.notify || char.properties.indicate) {
            try {
              await char.setNotifyValue(true);
            } catch (e) {
              debugPrint('No se pudo suscribir a ${char.uuid}: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error setting up notifications: $e');
    }
  }

  void _scheduleReconnection(BluetoothDevice device) {
    _reconnectionTimer?.cancel();

    if (_reconnectionAttempts >= MAX_RECONNECTION_ATTEMPTS) {
      return;
    }

    _reconnectionAttempts++;
    final delay = Duration(seconds: _reconnectionAttempts * 3);
    _reconnectionTimer = Timer(delay, () async {
      if (_connectedDevice == null && !_isConnecting) {
        final success = await connectToDevice(device);
        if (!success) {
          _scheduleReconnection(device);
        }
      }
    });
  }

  Future<void> disconnectDevice() async {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _reconnectionAttempts = 0;

    if (_connectedDevice == null) return;

    try {
      _connectionSubscription?.cancel();
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _deviceController.add(null);
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      _clearSavedDevice();
      onDeviceDisconnected?.call();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  Future<bool> sendNotificationToWearable(Map<String, dynamic> data) async {
    if (_connectedDevice == null) {
      return false;
    }

    try {
      final services = await _connectedDevice!.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            final dataString = jsonEncode(data);
            final dataBytes = utf8.encode(dataString);
            await char.write(dataBytes);
            _connectionStateController.add(BluetoothConnectionState.connected);
            return true;
          }
        }
      }

      debugPrint('No se encontró característica de escritura');
      return false;
    } catch (e) {
      debugPrint('Error sending to wearable: $e');
      return false;
    }
  }

  Future<bool> _checkPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ];

      final statuses = await permissions.request();
      final allGranted = statuses.values.every((s) => s.isGranted);
      return allGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }

    return false;
  }

  Future<bool> isBluetoothOn() async {
    try {
      return await FlutterBluePlus.isOn;
    } catch (e) {
      return false;
    }
  }

  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      debugPrint('Error turning on Bluetooth: $e');
    }
  }


  void dispose() {
    _reconnectionTimer?.cancel();
    _adapterStateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _scanResultsController.close();
    _connectionStateController.close();
    _deviceController.close();
    _batteryLevelController.close();
    _heartRateController.close();
    _stepsController.close();
    FlutterBluePlus.stopScan();
    _connectedDevice?.disconnect();
    _isInitialized = false;
  }
}
