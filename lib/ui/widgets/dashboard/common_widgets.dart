import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models.dart';
import '../../ui_helpers.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final List<Color>? gradientColors;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 30,
    this.opacity = 0.05,
    this.borderRadius = 24,
    this.gradientColors,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: isDark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.05)
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? [
                  isDark 
                    ? Colors.white.withValues(alpha: opacity) 
                    : Colors.white.withValues(alpha: opacity * 2),
                  isDark 
                    ? Colors.white.withValues(alpha: opacity * 0.5) 
                    : Colors.white.withValues(alpha: opacity),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

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

class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;

  const StyledTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const SectionLabel({
    super.key,
    required this.label,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: cs.primary.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white54 : Colors.black45,
                  letterSpacing: 1.0,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
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

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.02);

    return ExcludeSemantics(
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                  height: 240, width: double.infinity, color: Colors.white),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                        height: 112,
                        child: ListView.builder(
                            itemCount: 4,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (_, __) => Container(
                                width: 72,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white)))),
                    const SizedBox(height: 32),
                    Container(
                        height: 20,
                        width: 140,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    ...List.generate(
                        3,
                        (i) => Container(
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white)))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  final Category category;
  final double size;
  final Color? color;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      UIHelpers.getCategoryIcon(category),
      size: size,
      color: color ?? UIHelpers.getCategoryColor(category),
    );
  }
}

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

class PrimaryChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const PrimaryChipButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(14),
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
            borderRadius: BorderRadius.circular(14),
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
                          fontFamily: 'Outfit'))
                ])),
          ),
        ),
      ),
    );
  }
}

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
          color: active
              ? (isDark ? cs.primary.withValues(alpha: 0.2) : Colors.white)
              : Colors.transparent,
          boxShadow: active && !isDark
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            color: active
                ? cs.primary
                : (isDark ? Colors.white38 : Colors.black38),
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}
