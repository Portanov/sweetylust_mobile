// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/websocket_model.dart';

class WebSocketService {
  static const String SOCKET_URL = 'https://api.sweetylust.com/tv-connection';

  IO.Socket? _socket;
  final StateController<String> _connectionStatus = StateController<String>(
    'Desconectado',
  );
  final StateController<bool> _isConnected = StateController<bool>(false);
  final StateController<String> _roomId = StateController<String>('');
  final StateController<String> _mobileStatus = StateController<String>(
    'No conectado',
  );
  final StateController<List<OrderItemWS>> _products =
      StateController<List<OrderItemWS>>([]);
  final StateController<String> _currentOrder = StateController<String>('');
  final StateController<bool> _isOrderCompleted = StateController<bool>(false);
  final StateController<String?> _errorMessage = StateController<String?>(null);

  final _qrCodeStream = StreamController<String>.broadcast();
  final _orderScannedStream = StreamController<String>.broadcast();
  final _productsStream = StreamController<List<OrderItemWS>>.broadcast();
  final _mobileConnectedStream = StreamController<bool>.broadcast();
  final _orderCompletedStream = StreamController<String>.broadcast();
  final _errorStream = StreamController<String>.broadcast();
  final _logStream = StreamController<String>.broadcast(); // ← NUEVO

  // Getters
  StateController<String> get connectionStatus => _connectionStatus;
  StateController<bool> get isConnected => _isConnected;
  StateController<String> get roomId => _roomId;
  StateController<String> get mobileStatus => _mobileStatus;
  StateController<List<OrderItemWS>> get products => _products;
  StateController<String> get currentOrder => _currentOrder;
  StateController<bool> get isOrderCompleted => _isOrderCompleted;
  StateController<String?> get errorMessage => _errorMessage;

  // Streams
  Stream<String> get onQRCodeGenerated => _qrCodeStream.stream;
  Stream<String> get onOrderScanned => _orderScannedStream.stream;
  Stream<List<OrderItemWS>> get onProductsReceived => _productsStream.stream;
  Stream<bool> get onMobileConnected => _mobileConnectedStream.stream;
  Stream<String> get onOrderCompleted => _orderCompletedStream.stream;
  Stream<String> get onError => _errorStream.stream;
  Stream<String> get onLog => _logStream.stream; // ← NUEVO

  void connect() {
    if (_socket != null && _socket!.connected) {
      _logStream.add('⚠️ Ya estás conectado');
      return;
    }

    // Limpia una instancia anterior que haya quedado en estado inconsistente.
    if (_socket != null) {
      _socket!.offAny();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _logStream.add('🔌 Conectando a: $SOCKET_URL');
    _connectionStatus.state = 'Conectando...';

    try {
      _socket = IO.io(
        SOCKET_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io')
            .disableAutoConnect()
            .enableForceNew()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _logStream.add('📡 Socket creado, conectando...');
      _socket!.connect();

      _socket!.onConnect((_) {
        _logStream.add('✅ Conectado al servidor');
        _isConnected.state = true;
        _connectionStatus.state = 'Conectado';
        _errorMessage.state = null;
        _initTV();
      });

      _socket!.onDisconnect((_) {
        _logStream.add('⚠️ Desconectado del servidor');
        _isConnected.state = false;
        _connectionStatus.state = 'Desconectado';
        _mobileStatus.state = 'No conectado';
      });

      _socket!.onError((error) {
        final message = 'Error de socket: $error';
        _logStream.add('❌ $message');
        _errorMessage.state = message;
        _errorStream.add(message);
      });

      _socket!.onConnectError((error) {
        _logStream.add('❌ Error de conexión: $error');
        _isConnected.state = false;
        _connectionStatus.state = 'Error de conexión';
        final message = 'Error de conexión: $error';
        _errorMessage.state = message;
        _errorStream.add(message);
      });

      _socket!.onReconnect((attempt) {
        _logStream.add('🔄 Reconectado después de $attempt intentos');
        _connectionStatus.state = 'Conectado';
        _isConnected.state = true;
        _initTV();
      });

      _socket!.on('tv-initialized', (data) {
        final payload = _asJsonMap(data);
        _logStream.add('📺 TV inicializada: ${payload['roomId']}');
        final response = TVInitResponse.fromJson(payload);
        _roomId.state = response.roomId;
        _qrCodeStream.add(response.qrData);
      });

      _socket!.on('tv-init-error', (data) {
        final payload = _asJsonMap(data);
        final message =
            payload['message']?.toString() ?? 'Error al inicializar TV';
        _logStream.add('❌ $message');
        _errorMessage.state = message;
        _errorStream.add(message);
      });

      _socket!.on('qr-scan-error', (data) {
        final payload = _asJsonMap(data);
        final message =
            payload['message']?.toString() ?? 'Error al escanear código QR';
        _logStream.add('❌ $message');
        _errorMessage.state = message;
        _errorStream.add(message);
      });

      _socket!.on('mobile-connected', (data) {
        _logStream.add('📱 Móvil conectado');
        _mobileStatus.state = 'Conectado';
        _mobileConnectedStream.add(true);
      });

      _socket!.on('order-scanned', (data) {
        final payload = _asJsonMap(data);
        _logStream.add('📦 Orden escaneada: ${payload['orderBarcode']}');
        final event = OrderScannedEvent.fromJson(payload);
        _currentOrder.state = event.orderBarcode;
        _orderScannedStream.add(event.orderBarcode);
      });

      _socket!.on('order-products-response', (data) {
        final payload = _asJsonMap(data);
        _logStream.add(
          '📋 Productos recibidos: ${payload['products']?.length}',
        );
        final response = OrderProductsResponse.fromJson(payload);
        _products.state = response.products;
        _productsStream.add(response.products);
      });

      _socket!.on('order-products-error', (data) {
        final payload = _asJsonMap(data);
        final message =
            payload['message']?.toString() ?? 'Error al obtener productos';
        _logStream.add('❌ $message');
        _errorMessage.state = message;
        _errorStream.add(message);
      });

      _socket!.on('order-scan-error', (data) {
        final payload = _asJsonMap(data);
        final message =
            payload['message']?.toString() ?? 'Error al escanear orden';
        _logStream.add('❌ $message');
        _errorMessage.state = message;
        _errorStream.add(message);
      });

      _socket!.on('order-packing-completed', (data) {
        final payload = _asJsonMap(data);
        _logStream.add('✅ Orden completada: ${payload['orderBarcode']}');
        _isOrderCompleted.state = true;
        _orderCompletedStream.add(payload['orderBarcode']?.toString() ?? '');
        _products.state = [];
        _currentOrder.state = '';
      });

      _socket!.on('order-packing-finished', (data) {
        final payload = _asJsonMap(data);
        _logStream.add('✅ Confirmación móvil: ${payload['orderBarcode']}');
        _isOrderCompleted.state = true;
        _orderCompletedStream.add(payload['orderBarcode']?.toString() ?? '');
        _products.state = [];
        _currentOrder.state = '';
      });

      _socket!.on('finish-packing-error', (data) {
        final payload = _asJsonMap(data);
        final message =
            payload['message']?.toString() ?? 'Error al finalizar empacado';
        _logStream.add('❌ $message');
        _errorMessage.state = message;
        _errorStream.add(message);
      });
    } catch (e) {
      _logStream.add('❌ Excepción al conectar: $e');
      _errorStream.add('Error al conectar: $e');
    }
  }

  void _initTV() {
    if (_socket != null && _socket!.connected) {
      _logStream.add('📺 Enviando init-tv...');
      _socket!.emit('init-tv', {'tvName': 'Empacadora Flutter'});
    } else {
      _logStream.add('⚠️ No se puede initTV: socket no conectado');
    }
  }

  void scanTVQR(String qrCode) {
    if (_socket != null && _socket!.connected) {
      _logStream.add('📱 Escaneando QR: $qrCode');
      _socket!.emit('scan-tv-qr', {'qrCode': qrCode});
    } else {
      _logStream.add('❌ No conectado al servidor');
      _errorStream.add('No conectado al servidor');
    }
  }

  void scanOrder(String orderBarcode) {
    if (_socket != null && _socket!.connected) {
      final cleanedBarcode = cleanOrderBarcode(orderBarcode);
      _isOrderCompleted.state = false;
      _logStream.add('📦 Escaneando orden: $cleanedBarcode');
      _socket!.emit('scan-order', {
        'orderBarcode': cleanedBarcode,
        'roomId': _roomId.state,
      });
    } else {
      _logStream.add('❌ No conectado al servidor');
      _errorStream.add('No conectado al servidor');
    }
  }

  void finishPacking({String? orderBarcode}) {
    if (_socket != null && _socket!.connected) {
      final resolvedOrder = cleanOrderBarcode(
        orderBarcode ?? _currentOrder.state,
      );

      if (resolvedOrder.isEmpty) {
        _logStream.add('❌ No hay orden para finalizar');
        _errorStream.add('No hay orden para finalizar');
        return;
      }

      _isOrderCompleted.state = false;
      _logStream.add('✅ Finalizando empacado de: $resolvedOrder');
      _socket!.emit('finish-order-packing', {
        'orderBarcode': resolvedOrder,
        'roomId': _roomId.state,
      });
    } else {
      _logStream.add('❌ No conectado al servidor');
      _errorStream.add('No conectado al servidor');
    }
  }

  String cleanOrderBarcode(String barcode) {
    if (barcode.isEmpty) return barcode;
    String cleaned = barcode.replaceFirst(RegExp(r'^0+'), '');
    return cleaned.isEmpty ? '0' : cleaned;
  }

  void disconnect() {
    _logStream.add('🔌 Desconectando...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected.state = false;
    _connectionStatus.state = 'Desconectado';
    _errorMessage.state = null;
  }

  void dispose() {
    disconnect();
    _qrCodeStream.close();
    _orderScannedStream.close();
    _productsStream.close();
    _mobileConnectedStream.close();
    _orderCompletedStream.close();
    _errorStream.close();
    _logStream.close();
  }

  bool get isSocketConnected => _socket?.connected ?? false;

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {'raw': data};
      }
    }

    return {'raw': data};
  }
}
