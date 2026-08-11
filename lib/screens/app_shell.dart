import 'package:curved_navigation_bar_pro/curved_navigation_bar_pro.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cart_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _index = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CartScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SweetyLust'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'BeautyStarlight',
          color: Colors.black,
          fontSize: 34,
        ),
        backgroundColor: Colors.white,
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: CurvedNavigationBarPro(
        barHeight: 70,
        fabSink: 12,
        fabGap: 6,
        cornerRadius: 17,
        notchShoulderRadius: 12,
        contentPadding: 8,
        activeIconSize: 22,
        inactiveIconSize: 24,
        navbarStyle: CNBPStyles.minimalMono,
        inactiveColor: Colors.grey,
        inactiveTextStyle: GoogleFonts.alumniSans(
          fontWeight: FontWeight.w300,
          fontSize: 16,
        ),
        shadowColor: Colors.black.withValues(alpha: 0.2),
        fabColor: const Color(0xFF461B27),
        activeTextStyle: GoogleFonts.alumniSans(
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        items: const [
          CurvedNavigationItemPro(
            inactiveIcon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Inicio',
          ),
          CurvedNavigationItemPro(
            inactiveIcon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart_sharp,
            label: 'Carrito',
            badgeText: '•',
          ),
          CurvedNavigationItemPro(
            inactiveIcon: Icons.notifications_active_outlined,
            activeIcon: Icons.notifications_active_sharp,
            label: 'Alertas',
          ),
          CurvedNavigationItemPro(
            inactiveIcon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Perfil',
          ),
        ],
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
