import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sweetylust/providers/providers.dart';
import 'package:sweetylust/screens/addresses_screen.dart';
import 'package:sweetylust/screens/ble_devices_screen.dart';
import 'package:sweetylust/screens/login_screen.dart';
import 'package:sweetylust/screens/orders_screen.dart';
import 'package:sweetylust/screens/personal_info_screen.dart';
import 'package:sweetylust/screens/support_screen.dart';
import 'package:sweetylust/widgets/action_item.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'MI PERFIL',
                style: GoogleFonts.alumniSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),

              const CircleAvatar(
                radius: 70,

                backgroundImage: AssetImage('assets/images/nohacenada.jpg'),
                backgroundColor: Color(0xFFF2F2F5),
              ),
              const SizedBox(height: 20),

              Text(
                'Pollo Feliz',
                style: GoogleFonts.poiretOne(fontSize: 36, color: Colors.black),
              ),
              const SizedBox(height: 40),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CUENTA',
                  style: GoogleFonts.alumniSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              ActionItem(
                title: 'Información Personal',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalInfoScreen(),
                    ),
                  );
                },
              ),
              ActionItem(
                title: 'Direcciones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddressesScreen()),
                  );
                },
              ),
              ActionItem(
                title: 'Vincular BLE',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BleDevicesScreen()),
                  );
                },
              ),
              ActionItem(
                title: 'Pedidos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrdersScreen()),
                  );
                },
              ),
              ActionItem(
                title: 'Soporte',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA8A8),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  ),
                  onPressed: _isLoggingOut ? null : _handleLogout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isLoggingOut ? 'CERRANDO...' : 'CERRAR SESIÓN',
                        style: GoogleFonts.alumniSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      _isLoggingOut
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.logout_outlined, size: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
