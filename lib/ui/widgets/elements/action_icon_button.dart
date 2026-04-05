import 'package:flutter/material.dart';

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  const ActionIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
      ),
      child: IconButton(
        icon: Icon(icon,
            size: 14,
            color: color ?? (isDark ? Colors.white70 : Colors.black54)),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
