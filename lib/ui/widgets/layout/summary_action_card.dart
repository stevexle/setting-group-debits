import 'package:flutter/material.dart';
import '../base/glass_container.dart';

class SummaryActionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry? padding;

  final VoidCallback? onTap;
  final String? actionLabel;

  const SummaryActionCard({
    super.key,
    required this.title,
    required this.children,
    this.gradientColors,
    this.padding,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: GlassContainer(
          padding: padding ?? const EdgeInsets.all(20),
          gradientColors: gradientColors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white60 
                          : Colors.black54,
                    ),
                  ),
                  if (onTap != null)
                    Text(
                      actionLabel ?? 'VIEW ALL',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
