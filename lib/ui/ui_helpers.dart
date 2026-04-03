import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../l10n/strings.dart';

class UIHelpers {
  static const List<Color> avatarColors = [
    Color(0xFF5B5BF6), // Blue
    Color(0xFF00BDD4), // Cyan
    Color(0xFFFF6B9D), // Pink
    Color(0xFFFFB74D), // Orange
    Color(0xFF66BB6A), // Green
    Color(0xFFBA68C8), // Purple
    Color(0xFFEF5350), // Red
    Color(0xFF4DB6AC), // Teal
  ];

  static Color getAvatarColor(int index) {
    return avatarColors[index % avatarColors.length];
  }

  static IconData getCategoryIcon(Category category) {
    switch (category) {
      case Category.food: return Icons.restaurant_rounded;
      case Category.drink: return Icons.local_drink_rounded;
      case Category.shopping: return Icons.shopping_bag_rounded;
      case Category.transport: return Icons.directions_bus_rounded;
      case Category.entertainment: return Icons.movie_filter_rounded;
      case Category.home: return Icons.home_rounded;
      case Category.health: return Icons.favorite_rounded;
      case Category.other: return Icons.category_rounded;
    }
  }

  static Color getCategoryColor(Category category) {
    switch (category) {
      case Category.food: return const Color(0xFFFFB74D);
      case Category.drink: return const Color(0xFF64B5F6);
      case Category.shopping: return const Color(0xFFF06292);
      case Category.transport: return const Color(0xFF4DB6AC);
      case Category.entertainment: return const Color(0xFF9575CD);
      case Category.home: return const Color(0xFFAED581);
      case Category.health: return const Color(0xFFE57373);
      case Category.other: return const Color(0xFF90A4AE);
    }
  }

  static void showLiquidDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      const SizedBox(height: 16),
                      content,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.of(context).cancel))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: isDestructive ? cs.error : cs.primary),
                  onPressed: () { onConfirm(); Navigator.pop(ctx); },
                  child: Text(confirmLabel),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  static Widget showLiquidDialogWidget({
    required BuildContext context,
    required String title,
    required Widget content,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      const SizedBox(height: 16),
                      content,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.of(context).cancel))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: isDestructive ? cs.error : cs.primary),
                  onPressed: () { onConfirm(); Navigator.pop(context); },
                  child: Text(confirmLabel),
                )),
              ]),
            ],
          ),
        ),
      );
  }
  static String formatSmartDate(DateTime dt, AppStrings s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    if (dateOnly == today) {
      return DateFormat('HH:mm').format(dt);
    } else if (dateOnly == yesterday) {
      return '${s.yesterday} ${DateFormat('HH:mm').format(dt)}';
    } else {
      return '${DateFormat('dd/MM').format(dt)} ${DateFormat('HH:mm').format(dt)}';
    }
  }
}
