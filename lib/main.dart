import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sweetylust/providers/http_provider.dart';
import 'package:sweetylust/screens/splash_screen.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sweetylust/services/permission_service.dart';
import 'package:sweetylust/services/notification_service.dart';
import 'package:sweetylust/services/ble_service.dart';
import './firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Stripe.publishableKey = dotenv.get('stripe_key');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final permissionService = PermissionService();
  await permissionService.initializePermissions();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final notificationService = NotificationService(
      httpClient: ref.read(httpClientProvider),
      apiUrl: ref.read(apiUrlProvider),
    );
    await notificationService.initialize();
    final bleService = BLEService();
    await bleService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'SweetyLust',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
