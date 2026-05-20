import 'package:dndnb/utils/theme.dart';
import 'package:flutter/material.dart';

/// A small pill badge showing a session status (Confirmée / Annulée / Modifiée).
/// Typically placed as a [Positioned] overlay on the session card.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  static Color colorFor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmée':
        return const Color(0xFF2E7D32); // deep green
      case 'annulée':
        return const Color(0xFFC62828); // deep red
      case 'modifiée':
        return const Color(0xFFE65100); // deep orange
      default:
        return Colors.transparent;
    }
  }

  static IconData iconFor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmée':
        return Icons.check_circle_outline;
      case 'annulée':
        return Icons.cancel_outlined;
      case 'modifiée':
        return Icons.edit_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    if (color == Colors.transparent) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DndSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: DndRadius.sm,
          bottomRight: DndRadius.sm,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(status), size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
