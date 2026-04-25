import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../ui_helpers.dart';
import '../../widgets/base/glass_container.dart';

class PlanDistributionTab extends StatelessWidget {
  final BudgetPlan plan;
  final NumberFormat fmt;
  final bool isDark;
  final AppStrings s;

  const PlanDistributionTab({
    super.key,
    required this.plan,
    required this.fmt,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    // Group tasks by category and sum costs
    final Map<Category, double> distribution = {};
    for (final task in plan.checklist) {
      distribution[task.category] = (distribution[task.category] ?? 0) + task.estimatedCost;
    }
    
    // Also include itinerary costs if any (usually trip, but just in case)
    if (plan.itinerary.isNotEmpty) {
      final tripCost = plan.itinerary.fold<double>(0, (sum, i) => sum + i.estimatedCost);
      distribution[Category.transport] = (distribution[Category.transport] ?? 0) + tripCost;
    }

    final totalPlanned = distribution.values.fold<double>(0, (sum, val) => sum + val);
    final List<PieChartSectionData> sections = [];
    
    distribution.forEach((cat, amount) {
      if (amount > 0) {
        sections.add(PieChartSectionData(
          color: UIHelpers.getCategoryColor(cat),
          value: amount,
          title: totalPlanned > 0 ? '${(amount / totalPlanned * 100).toStringAsFixed(0)}%' : '',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text("PHÂN BỔ CHI PHÍ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: totalPlanned > 0 
                    ? PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2))
                    : const Center(child: Text("Chưa có dữ liệu chi phí")),
                ),
                const SizedBox(height: 24),
                Text(fmt.format(totalPlanned), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                Text("TỔNG DỰ TÍNH", style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ... (distribution.entries.toList()..sort((a,b) => b.value.compareTo(a.value))).map((entry) => _buildCategoryRow(entry.key, entry.value, totalPlanned)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(Category cat, double amount, double total) {
    final color = UIHelpers.getCategoryColor(cat);
    final percentage = total > 0 ? amount / total : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(UIHelpers.getCategoryIcon(cat), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(UIHelpers.getCategoryName(cat, s), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 4,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(fmt.format(amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}
