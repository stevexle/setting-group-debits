import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base background color
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF0E0E1B) : Colors.white,
          ),
        ),
        // Overlay for depth and readability
        Positioned.fill(
          child: Container(
            color: isDark
                ? const Color(0xFF0E0E1B).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        // Subtle blur to create "frosted depth"
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
