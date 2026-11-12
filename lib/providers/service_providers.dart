import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/report_service.dart';
import '../services/user_service.dart';
import '../services/websocket_service.dart';
import 'http_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return AuthService(httpClient: httpClient, apiUrl: apiUrl);
});

final userServiceProvider = Provider<UserService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return UserService(httpClient: httpClient, apiUrl: apiUrl);
});

final productServiceProvider = Provider<ProductService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return ProductService(httpClient: httpClient, apiUrl: apiUrl);
});

final cartServiceProvider = Provider<CartService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return CartService(httpClient: httpClient, apiUrl: apiUrl);
});

final addressServiceProvider = Provider<AddressService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return AddressService(httpClient: httpClient, apiUrl: apiUrl);
});

final orderServiceProvider = Provider<OrderService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return OrderService(httpClient: httpClient, apiUrl: apiUrl);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return NotificationService(httpClient: httpClient, apiUrl: apiUrl);
});

final reportServiceProvider = Provider<ReportService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return ReportService(httpClient: httpClient, apiUrl: apiUrl);
});
