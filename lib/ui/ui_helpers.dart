import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';

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
      default: return Icons.category_rounded;
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
      default: return const Color(0xFF90A4AE);
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
      return '${s.today} ${DateFormat('HH:mm').format(dt)}';
    } else if (dateOnly == yesterday) {
      return '${s.yesterday} ${DateFormat('HH:mm').format(dt)}';
    } else {
      return '${DateFormat('dd/MM').format(dt)} ${DateFormat('HH:mm').format(dt)}';
    }
  }

  static Map<String, List<BaseTransaction>> groupTransactionsByMonth(List<BaseTransaction> txs) {
    // Ensure chronological order (newest first)
    final sorted = [...txs]..sort((a, b) => b.date.compareTo(a.date));
    final grouped = <String, List<BaseTransaction>>{};
    
    for (final tx in sorted) {
      final key = DateFormat('MMMM yyyy').format(tx.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(tx);
    }
    return grouped;
  }

  static void showAccountPicker({
    required BuildContext context,
    required AppState state,
    required Function(Account) onSelected,
  }) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.navWallet, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            if (state.accounts.isEmpty) 
               const Padding(
                 padding: EdgeInsets.symmetric(vertical: 20),
                 child: Text("Chưa có ví nào để hạch toán", style: TextStyle(color: Colors.white38)),
               ),
            ...state.accounts.map((acc) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.account_balance_wallet_rounded, color: Theme.of(context).colorScheme.primary),
              title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(fmt.format(acc.currentBalance), style: const TextStyle(fontSize: 12, color: Colors.white38)),
              onTap: () {
                onSelected(acc);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    // Remove all non-numeric characters
    final cleanString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return const TextEditingValue();

    final value = double.parse(cleanString);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value).trim();

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
