import 'package:flutter/material.dart';
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

    // Aggregated plans from all groups or root level plans
    final allPlans = state.groups.expand((g) => g.plans).toList();

    return MainScreenScaffold(
      title: s.planningTitle,
      children: [
        _buildCreatePlanAction(context, s, isDark),
        const SizedBox(height: 24),
        if (allPlans.isEmpty)
          const EmptyCard(
            message:
                'Bạn chưa có kế hoạch nào. Hãy lập kế hoạch cho chuyến đi hoặc sự kiện sắp tới!',
            icon: Icons.auto_awesome_motion_rounded,
          )
        else
          ...allPlans.map((plan) => GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlanDetailScreen(plan: plan))),
                child: _buildPlanCard(context, plan, isDark),
              )),
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

  Widget _buildPlanCard(BuildContext context, dynamic plan, bool isDark) {
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
                _buildPlanTypeTag(plan.type, isDark),
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
                      const Text('DỰ TRÙ',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                              letterSpacing: 1.0)),
                      Text('${plan.budgetTotal}đ',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHI THỰC TẾ',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                              letterSpacing: 1.0)),
                      Text('${plan.currentSpent}đ',
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

  Widget _buildPlanTypeTag(dynamic type, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight_takeoff_rounded, size: 12, color: Colors.blue),
          SizedBox(width: 4),
          Text('DU LỊCH',
              style: TextStyle(
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
