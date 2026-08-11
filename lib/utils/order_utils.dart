import 'package:flutter/material.dart';

class OrderUtils {
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'procesando':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'enviado':
        return Colors.purple;
      case 'en_camino':
        return Colors.indigo;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'procesando':
        return 'Procesando';
      case 'confirmado':
        return 'Confirmado';
      case 'enviado':
        return 'Enviado';
      case 'en_camino':
        return 'En camino';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }
}
