import 'dart:ui';
import 'package:flutter/material.dart';
import 'ambient_glow.dart';

class LiquidBackground extends StatefulWidget {
  const LiquidBackground({super.key});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base background color
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF0E0E1B) : const Color(0xFFF8F9FF),
          ),
        ),

        // Aesthetic Floating Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Stack(
              children: [
                if (!isDark) ...[
                  // Top Left Floating Blob
                  Positioned(
                    top: -150 + (t * 50),
                    left: -100 + (t * 30),
                    child: AmbientGlow(
                      color: const Color(0xFF818CF8),
                      size: 600,
                      opacity: 0.22,
                    ),
                  ),
                  // Bottom Right Floating Blob
                  Positioned(
                    bottom: -200 + (t * 40),
                    right: -100 + (t * 60),
                    child: AmbientGlow(
                      color: const Color(0xFF6366F1),
                      size: 700,
                      opacity: 0.18,
                    ),
                  ),
                  // Center Floating Accents
                  Positioned(
                    top: 250 + (t * 100),
                    left: -200 + (t * 50),
                    child: AmbientGlow(
                      color: Colors.blueGrey,
                      size: 450,
                      opacity: 0.12,
                    ),
                  ),
                ] else ...[
                  // Dark mode floating blobs
                  Positioned(
                    top: -100 + (t * 40),
                    left: -100 + (t * 20),
                    child: AmbientGlow(
                      color: const Color(0xFF6366F1),
                      size: 650,
                      opacity: 0.28,
                    ),
                  ),
                  Positioned(
                    bottom: -150 + (t * 30),
                    right: -100 + (t * 50),
                    child: AmbientGlow(
                      color: const Color(0xFF818CF8),
                      size: 750,
                      opacity: 0.22,
                    ),
                  ),
                ],
              ],
            );
          },
        ),

        // Topper Gradient (Static for stability)
        if (!isDark)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blueGrey.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

        // Overlay for depth and readability
        Positioned.fill(
          child: Container(
            color: isDark
                ? const Color(0xFF0E0E1B).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),

        // High quality frosted blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
