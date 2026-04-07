import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/common_widgets.dart';
import '../../../l10n/strings.dart';

class BillShareStatsCard extends StatelessWidget {
  final int memberCount;
  final double weekly;
  final double monthly;
  final AppStrings s;
  final NumberFormat fmt;

  const BillShareStatsCard({
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
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor = isDark ? Colors.white70 : const Color(0xFF4B5563);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildColumnStat(
                s.people,
                '$memberCount',
                Icons.people_outline,
                const Color(0xFF5B5BF6),
                textColor,
                subColor,
                isDark),
          ),
          _buildDivider(isDark),
          Expanded(
            child: _buildColumnStat(
                s.thisWeek,
                fmt.format(weekly),
                Icons.calendar_view_week_rounded,
                const Color(0xFF00BDD4),
                textColor,
                subColor,
                isDark),
          ),
          _buildDivider(isDark),
          Expanded(
            child: _buildColumnStat(
                s.thisMonth,
                fmt.format(monthly),
                Icons.trending_up_rounded,
                const Color(0xFFFF6B9D),
                textColor,
                subColor,
                isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
    );
  }

  Widget _buildColumnStat(String label, String value, IconData icon,
      Color iconColor, Color textColor, Color subColor, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: subColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
