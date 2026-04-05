import 'package:flutter/material.dart';

class HistoryTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;

  const HistoryTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? cs.primary : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: active
                ? Colors.white
                : (isDark ? Colors.white38 : Colors.black45),
          ),
        ),
      ),
    );
  }
}
