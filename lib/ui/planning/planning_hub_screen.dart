import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../l10n/strings.dart';
import '../widgets/common_widgets.dart';
import 'add_plan_modal.dart';
import 'plan_detail_screen.dart';

class PlanningHubScreen extends StatelessWidget {
  const PlanningHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    // Aggregated plans from all groups or root level plans
    final allPlans = state.groups.expand((g) => g.plans).toList();

    return MainScreenScaffold(
      title: s.planningTitle,
      children: [
        _buildCreatePlanAction(context, s, isDark),
        const SizedBox(height: 24),
        allPlans.isEmpty
            ? EmptyCard(
                message: s.noPlansMsg,
                icon: Icons.auto_awesome_motion_rounded,
              )
            : Column(
                children: allPlans
                    .map((plan) => GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PlanDetailScreen(plan: plan))),
                          child: _buildPlanCard(context, plan, isDark, s, fmt),
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildCreatePlanAction(
      BuildContext context, AppStrings s, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return SummaryActionCard(
      title: s.planningOverview,
      children: [
        Center(
          child: Column(
            children: [
              Icon(Icons.auto_awesome_motion_rounded,
                  size: 32, color: cs.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                s.addPlan,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              PrimaryChipButton(
                label: s.create,
                icon: Icons.add_rounded,
                color: cs.primary,
                onTap: () => AddPlanModal.show(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
      BuildContext context, dynamic plan, bool isDark, AppStrings s, NumberFormat fmt) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPlanTypeTag(context, plan.type, isDark, s),
                const Icon(Icons.more_horiz_rounded,
                    size: 18, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.estimatedBudget,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                              letterSpacing: 1.0)),
                      Text(fmt.format(plan.budgetTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.actualSpent,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                              letterSpacing: 1.0)),
                      Text(fmt.format(plan.currentSpent),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orangeAccent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
                plan.currentSpent /
                    (plan.budgetTotal > 0 ? plan.budgetTotal : 1),
                cs),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTypeTag(
      BuildContext context, dynamic type, bool isDark, AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flight_takeoff_rounded, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(s.getPlanTypeName(type).toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, ColorScheme cs) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(),
            Text('${(progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: progress > 1 ? Colors.redAccent : cs.primary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
