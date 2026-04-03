import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import 'common_widgets.dart';

class DashboardStatsCard extends StatelessWidget {
  final int memberCount;
  final double weekly, monthly;
  final AppStrings s;
  final NumberFormat fmt;

  const DashboardStatsCard({
    super.key,
    required this.memberCount,
    required this.weekly,
    required this.monthly,
    required this.s,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassContainer(
      borderRadius: 24,
      opacity: isDark ? 0.08 : 0.4,
      blur: 20,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.people_outline_rounded,
            value: memberCount.toString(),
            label: s.people,
            isDark: isDark,
            iconColor: Colors.cyan,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            context,
            icon: Icons.analytics_outlined,
            value: _formatCompact(weekly),
            label: 'This week',
            isDark: isDark,
            iconColor: Colors.indigoAccent,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            context,
            icon: Icons.trending_up_rounded,
            value: _formatCompact(monthly),
            label: 'This month',
            isDark: isDark,
            iconColor: Colors.pinkAccent,
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return fmt.format(value);
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? Colors.white10 : Colors.black12,
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withValues(alpha: 0.15),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'Outfit',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black38,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }
}

class SettleUpCard extends StatelessWidget {
  final List<Settlement> settlements;
  final AppStrings s;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const SettleUpCard({
    super.key,
    required this.settlements,
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
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.indigoAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.settlement,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: 'Outfit',
                  ),
                ),
                Text(
                  '${settlements.length} ${s.settlementTitle.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 13,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Paid', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
