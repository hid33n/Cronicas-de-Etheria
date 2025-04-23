import 'package:flutter/material.dart';

class ResChip extends StatelessWidget {
  final String assetPath;
  final int qty;
  final int perHour;

  const ResChip(this.assetPath, {required this.qty, required this.perHour});

  const ResChip.minimal(this.assetPath,
      {required this.qty, required this.perHour, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800], // Fondo más oscuro
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 20, height: 20),
          const SizedBox(width: 6),
          Text(
            '$qty',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (perHour > 0) ...[
            const SizedBox(width: 4),
            Text(
              '+$perHour/h',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
