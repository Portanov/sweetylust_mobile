import 'package:flutter/material.dart';

Widget buildEmptyAddress(context) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F5),
      borderRadius: BorderRadius.circular(16.0),
    ),
    child: Column(
      children: [
        const Text(
          'No tienes direcciones guardadas',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF232323),
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('Agregar dirección'),
        ),
      ],
    ),
  );
}


