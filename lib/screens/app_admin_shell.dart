import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/providers/admin_shell_provider.dart';
import 'package:sweetylust/screens/ble_admin_screen.dart';
import 'package:sweetylust/screens/qr_scanner_screen.dart';
import 'packing_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  final List<Widget> _screens = const [QRScanScreen(), PackingScreen(), MonitorScreen()];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(adminTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(adminTabIndexProvider.notifier).state = index;
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green[400],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Conectar TV',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Empacar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Monitoreo',
          ),
        ],
      ),
    );
  }
}
