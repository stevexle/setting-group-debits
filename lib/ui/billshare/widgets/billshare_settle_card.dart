import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../widgets/common_widgets.dart';

class SettleUpCard extends StatelessWidget {
  final List<Settlement> settlements;
  final bool hasPendingConfirmations;
  final AppStrings s;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const SettleUpCard({
    super.key,
    required this.settlements,
    this.hasPendingConfirmations = false,
    required this.s,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 24,
      opacity: isDark ? 0.08 : 0.05,
      blur: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.indigo.withValues(alpha: 0.2),
            ),
            child: Icon(
              hasPendingConfirmations ? Icons.notification_important_rounded : Icons.auto_awesome_rounded,
              color: hasPendingConfirmations ? Colors.orangeAccent : Colors.indigoAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPendingConfirmations ? s.needsConfirmation : s.settlement,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: hasPendingConfirmations ? Colors.orangeAccent : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                Text(
                  hasPendingConfirmations 
                    ? s.waitingForYou 
                    : '${settlements.length} ${s.settlementTitle.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.settleNow,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
