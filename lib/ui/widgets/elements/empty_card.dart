import 'package:flutter/material.dart';
import '../base/glass_container.dart';

class EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyCard({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      opacity: 0.02,
      child: Column(
        children: [
          Icon(icon, size: 32, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
