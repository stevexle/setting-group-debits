import 'package:flutter/material.dart';

class DashboardFAB extends StatelessWidget {
  final bool enabled;
  final String label;
  final ColorScheme cs;
  final VoidCallback onTap;

  const DashboardFAB({
    super.key,
    required this.enabled,
    required this.label,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: enabled ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.8)]),
          boxShadow: [
            BoxShadow(
                color: cs.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ))
                ])),
          ),
        ),
      ),
    );
  }
}
