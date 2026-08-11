import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionItem extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const ActionItem({super.key, required this.title, required this.onTap});

  @override
  State<ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<ActionItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.poiretOne(fontSize: 16, color: Colors.black87),
            ),
            const Icon(Icons.arrow_right, size: 24, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
