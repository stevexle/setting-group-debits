import 'package:flutter/material.dart';
import '../base/glass_container.dart';

class AppOption {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  AppOption({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

class AppOptionsSheet extends StatelessWidget {
  final String title;
  final List<AppOption> options;

  const AppOptionsSheet({
    super.key,
    required this.title,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: option.onTap,
              borderRadius: BorderRadius.circular(16),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    Icon(option.icon, color: option.color ?? Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Text(
                      option.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
