import 'package:flutter/material.dart';
import '../base/glass_container.dart';

class AppOption {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool enabled;
  final bool isDestructive;

  AppOption({
    required this.label,
    required this.icon,
    this.onTap,
    this.color,
    this.enabled = true,
    this.isDestructive = false,
  });
}

class AppOptionsSheet extends StatelessWidget {
  final String title;
  final String? message;
  final Color? messageColor;
  final List<AppOption> options;

  const AppOptionsSheet({
    super.key,
    required this.title,
    required this.options,
    this.message,
    this.messageColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
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
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (messageColor ?? Colors.amber).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: (messageColor ?? Colors.amber).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security_rounded,
                            color: messageColor ?? Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: messageColor ?? Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    child: Opacity(
                      opacity: option.enabled ? 1.0 : 0.3,
                      child: InkWell(
                        onTap: option.enabled ? option.onTap : null,
                        borderRadius: BorderRadius.circular(16),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          child: Row(
                            children: [
                              Icon(option.icon,
                                  color: option.isDestructive
                                      ? Colors.redAccent
                                      : (option.color ??
                                          Theme.of(context).colorScheme.primary)),
                              const SizedBox(width: 16),
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: option.isDestructive ? Colors.redAccent : null,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Colors.white24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
