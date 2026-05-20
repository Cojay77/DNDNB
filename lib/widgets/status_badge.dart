import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(status);
    
    if (color == AppTheme.statusDefault) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: -8,
      top: 20,
      child: Transform.rotate(
        angle: 0.8,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          color: color,
          child: Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
