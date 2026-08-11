import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/screens/app_admin_shell.dart';

import '../providers/providers.dart';
import 'app_shell.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3), () {});

    await ref.read(authProvider.notifier).initializeSession();

    if (!mounted) return;

    final authState = ref.read(authProvider);
    final nextScreen = authState.isAuthenticated
        ? authState.user?.role == 'admin' ? AdminHomeScreen() : MyHomePage(title: 'SweetyLust')
        : const LoginScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/paleta.jpg', fit: BoxFit.cover),

          Container(color: Colors.black.withValues(alpha: 0.7)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sweety Lust',
                  style: TextStyle(
                    fontFamily: 'Cursive',
                    fontSize: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
