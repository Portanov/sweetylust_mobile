import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/providers/permission_provider.dart';
import 'package:sweetylust/widgets/notification_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadNotifications();
  }

  Future<void> _checkPermissions() async {
    final permissionNotifier = ref.read(permissionNotifierProvider.notifier);
    final hasPermission = ref
        .read(permissionNotifierProvider)
        .hasNotificationsPermission;

    if (!hasPermission) {
      final granted = await permissionNotifier.requestNotifications();
      if (granted) {
        _loadNotifications();
      }
    }
  }

  void _loadNotifications() {
    setState(() {
      _notifications.addAll([
        {
          "title": "Pedido enviado",
          "description": "Tu pedido #002 ha sido enviado...",
        },
        {
          "title": "Pedido cancelado",
          "description": "Tu pedido #002 ha sido cancelado...",
        },
        {
          "title": "Pedido enviado",
          "description": "Tu pedido #002 ha sido enviado...",
        },
        {
          "title": "Oferta especial",
          "description": "¡Aprovecha nuestras ofertas!",
        },
        {"title": "Recordatorio", "description": "No olvides tu cita de hoy"},
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(permissionNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (!permissionState.hasNotificationsPermission)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_off,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Las notificaciones están desactivadas',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final granted = await ref
                            .read(permissionNotifierProvider.notifier)
                            .requestNotifications();
                        if (granted) {
                          setState(() {});
                        }
                      },
                      child: const Text('Activar'),
                    ),
                  ],
                ),
              ),

            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

            Expanded(
              child: _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay notificaciones',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        return NotificationCard(
                          title: notif['title']!,
                          description: notif['description']!,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
