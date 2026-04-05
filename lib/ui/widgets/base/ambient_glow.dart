import 'package:flutter/material.dart';

class AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const AmbientGlow({
    super.key,
    required this.color,
    this.size = 200,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
