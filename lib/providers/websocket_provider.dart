import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import '../models/websocket_model.dart';

// ============================================================
// PROVIDER DEL SERVICIO (Singleton)
// ============================================================
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ============================================================
// STATE PROVIDERS - Estados del WebSocket
// ============================================================

// Estado de conexión (String: 'Conectado', 'Desconectado', etc.)
final wsConnectionStatusProvider = Provider<String>((ref) {
  return ref.watch(
    webSocketNotifierProvider.select((state) => state.connectionStatus),
  );
});

// Estado de conexión (bool)
final wsIsConnectedProvider = Provider<bool>((ref) {
  return ref.watch(
    webSocketNotifierProvider.select((state) => state.isConnected),
  );
});

// ID de la sala
final wsRoomIdProvider = Provider<String>((ref) {
  return ref.watch(webSocketNotifierProvider.select((state) => state.roomId));
});

// Estado del móvil
final wsMobileStatusProvider = Provider<String>((ref) {
  return ref.watch(
    webSocketNotifierProvider.select((state) => state.mobileStatus),
  );
});

// Lista de productos
final wsProductsProvider = Provider<List<OrderItemWS>>((ref) {
  return ref.watch(webSocketNotifierProvider.select((state) => state.products));
});

// Orden actual
final wsCurrentOrderProvider = Provider<String>((ref) {
  return ref.watch(
    webSocketNotifierProvider.select((state) => state.currentOrder),
  );
});

// Estado de orden completada
final wsIsOrderCompletedProvider = Provider<bool>((ref) {
  return ref.watch(
    webSocketNotifierProvider.select((state) => state.isOrderCompleted),
  );
});

// ============================================================
// STREAM PROVIDERS - Eventos en tiempo real
// ============================================================

// Evento: QR generado
final wsQRCodeStreamProvider = StreamProvider<String>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.onQRCodeGenerated;
});

// Evento: Orden escaneada
final wsOrderScannedStreamProvider = StreamProvider<String>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.onOrderScanned;
});

// Evento: Productos recibidos
final wsProductsStreamProvider = StreamProvider<List<OrderItemWS>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.onProductsReceived;
});

// Evento: Móvil conectado
final wsMobileConnectedStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.onMobileConnected;
});

// Evento: Orden completada
final wsOrderCompletedStreamProvider = StreamProvider<String>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.onOrderCompleted;
});

// Evento: Errores
final wsErrorStreamProvider = StreamProvider<String>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.onError;
});

// ============================================================
// STATE NOTIFIER - Para acciones y estado mutable
// ============================================================

class WebSocketState {
  static const Object _noErrorChange = Object();

  final bool isConnected;
  final String connectionStatus;
  final String roomId;
  final String mobileStatus;
  final List<OrderItemWS> products;
  final String currentOrder;
  final bool isOrderCompleted;
  final String? error;

  WebSocketState({
    this.isConnected = false,
    this.connectionStatus = 'Desconectado',
    this.roomId = '',
    this.mobileStatus = 'No conectado',
    this.products = const [],
    this.currentOrder = '',
    this.isOrderCompleted = false,
    this.error,
  });

  WebSocketState copyWith({
    bool? isConnected,
    String? connectionStatus,
    String? roomId,
    String? mobileStatus,
    List<OrderItemWS>? products,
    String? currentOrder,
    bool? isOrderCompleted,
    Object? error = _noErrorChange,
  }) {
    return WebSocketState(
      isConnected: isConnected ?? this.isConnected,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      roomId: roomId ?? this.roomId,
      mobileStatus: mobileStatus ?? this.mobileStatus,
      products: products ?? this.products,
      currentOrder: currentOrder ?? this.currentOrder,
      isOrderCompleted: isOrderCompleted ?? this.isOrderCompleted,
      error: identical(error, _noErrorChange) ? this.error : error as String?,
    );
  }
}

// Notifier para manejar el estado del WebSocket
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final WebSocketService _service;
  bool _isListening = false;

  WebSocketNotifier(this._service) : super(WebSocketState()) {
    _listenToService();
  }

  void _listenToService() {
    if (_isListening) return;
    _isListening = true;

    // Escuchar cambios en la conexión
    _service.connectionStatus.addListener((_) {
      state = state.copyWith(connectionStatus: _service.connectionStatus.state);
    });

    _service.isConnected.addListener((_) {
      state = state.copyWith(isConnected: _service.isConnected.state);
    });

    _service.roomId.addListener((_) {
      state = state.copyWith(roomId: _service.roomId.state);
    });

    _service.mobileStatus.addListener((_) {
      state = state.copyWith(mobileStatus: _service.mobileStatus.state);
    });

    _service.products.addListener((_) {
      state = state.copyWith(products: _service.products.state);
    });

    _service.currentOrder.addListener((_) {
      state = state.copyWith(currentOrder: _service.currentOrder.state);
    });

    _service.isOrderCompleted.addListener((_) {
      state = state.copyWith(isOrderCompleted: _service.isOrderCompleted.state);
    });

    // Escuchar errores
    _service.onError.listen((error) {
      state = state.copyWith(error: error);
    });
  }

  // Acciones
  void connect() {
    _service.connect();
  }

  void disconnect() {
    _service.disconnect();
  }

  void scanTVQR(String qrCode) {
    _service.scanTVQR(qrCode);
  }

  void scanOrder(String orderBarcode) {
    _service.scanOrder(orderBarcode);
  }

  void finishPacking([String? orderBarcode]) {
    _service.finishPacking(orderBarcode: orderBarcode);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String cleanOrderBarcode(String barcode) {
    return _service.cleanOrderBarcode(barcode);
  }
}

// Provider del Notifier
final webSocketNotifierProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
      final service = ref.watch(webSocketServiceProvider);
      return WebSocketNotifier(service);
    });

// ============================================================
// PROVIDERS SELECTIVOS (para optimizar renders)
// ============================================================

// Solo el estado de conexión
final wsConnectionStateProvider = Provider<bool>((ref) {
  final state = ref.watch(webSocketNotifierProvider);
  return state.isConnected;
});

// Solo el estado de la sala
final wsRoomStateProvider = Provider<String>((ref) {
  final state = ref.watch(webSocketNotifierProvider);
  return state.roomId;
});

// Solo el estado del móvil
final wsMobileStateProvider = Provider<String>((ref) {
  final state = ref.watch(webSocketNotifierProvider);
  return state.mobileStatus;
});

// Solo los productos
final wsProductsStateProvider = Provider<List<OrderItemWS>>((ref) {
  final state = ref.watch(webSocketNotifierProvider);
  return state.products;
});

// Solo la orden actual
final wsCurrentOrderStateProvider = Provider<String>((ref) {
  final state = ref.watch(webSocketNotifierProvider);
  return state.currentOrder;
});

// Solo el estado de orden completada
final wsOrderCompletedStateProvider = Provider<bool>((ref) {
  final state = ref.watch(webSocketNotifierProvider);
  return state.isOrderCompleted;
});

// Solo el error
final wsErrorStateProvider = Provider<String?>((ref) {
  final state = ref.watch(webSocketNotifierProvider);
  return state.error;
});

final wsLogStreamProvider = StreamProvider<String>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.onLog;
});

// ============================================================
// PROVIDER PARA ACCIONES (métodos del WebSocket)
// ============================================================

final wsActionsProvider = Provider<WebSocketActions>((ref) {
  final notifier = ref.watch(webSocketNotifierProvider.notifier);
  return WebSocketActions(
    connect: notifier.connect,
    disconnect: notifier.disconnect,
    scanTVQR: notifier.scanTVQR,
    scanOrder: notifier.scanOrder,
    finishPacking: notifier.finishPacking,
    cleanOrderBarcode: notifier.cleanOrderBarcode,
    clearError: notifier.clearError,
  );
});

class WebSocketActions {
  final VoidCallback connect;
  final VoidCallback disconnect;
  final void Function(String) scanTVQR;
  final void Function(String) scanOrder;
  final void Function([String?]) finishPacking;
  final String Function(String) cleanOrderBarcode;
  final VoidCallback clearError;

  WebSocketActions({
    required this.connect,
    required this.disconnect,
    required this.scanTVQR,
    required this.scanOrder,
    required this.finishPacking,
    required this.cleanOrderBarcode,
    required this.clearError,
  });
}
