import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../l10n/strings.dart';
import '../../models.dart';
import '../widgets/common_widgets.dart';
import '../ui_helpers.dart';
import 'add_plan_screen.dart';
import 'plan_detail_screen.dart';

class PlanningHubScreen extends StatefulWidget {
  const PlanningHubScreen({super.key});

  @override
  State<PlanningHubScreen> createState() => _PlanningHubScreenState();
}

class _PlanningHubScreenState extends State<PlanningHubScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    // Aggregated plans from all sources, ensuring uniqueness by ID
    final allPlans = {
      ...state.plans,
      ...state.groups.expand((g) => g.plans),
    }.toList();
    allPlans.sort((a, b) => b.budgetTotal.compareTo(a.budgetTotal));

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
                  size: 24, color: cs.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                s.addPlan,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              PrimaryChipButton(
                label: s.create,
                icon: Icons.add_rounded,
                color: cs.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlanScreen())),
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
    
    List<Color> gradientColors;
    IconData typeIcon;
    switch (plan.type) {
      case PlanType.event:
        gradientColors = [Colors.orange.shade400, Colors.pink.shade400];
        typeIcon = Icons.celebration_rounded;
        break;
      case PlanType.living:
        gradientColors = [Colors.teal.shade400, Colors.green.shade400];
        typeIcon = Icons.home_rounded;
        break;
      case PlanType.trip:
      default:
        gradientColors = [Colors.blue.shade400, Colors.purple.shade400];
        typeIcon = Icons.flight_takeoff_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: gradientColors.map((c) => c.withValues(alpha: 0.85)).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                   Positioned(
                     right: -10,
                     top: -10,
                     child: Icon(typeIcon, size: 70, color: Colors.white.withValues(alpha: 0.25)),
                   ),
                   Padding(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             _buildPlanTypeTag(context, plan.type, isDark, s),
                             const Spacer(),
                             _buildStatusIndicator(plan, s, isDark),
                           ],
                         ),
                         const Spacer(),
                         Row(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   if (plan.startDate != null)
                                      _buildCountdown(plan, s, isDark),
                                   Text(
                                     plan.title,
                                     style: const TextStyle(
                                       fontSize: 18,
                                       fontWeight: FontWeight.w900,
                                       color: Colors.white,
                                       shadows: [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4)],
                                     ),
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ],
                               ),
                             ),
                             const SizedBox(width: 8),
                             const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white70),
                           ],
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Builder(
                builder: (context) {
                  final textColor = isDark ? Colors.white : Colors.black87;
                  final textSubColor = isDark ? Colors.white70 : Colors.black54;
                  final dividerColor = isDark ? Colors.white12 : Colors.black12;
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text(s.estimatedBudget,
                                     style: TextStyle(
                                         fontSize: 11,
                                         color: textSubColor,
                                         fontWeight: FontWeight.bold,
                                         letterSpacing: 0.5)),
                                 const SizedBox(height: 4),
                                 Text(fmt.format(plan.budgetTotal),
                                     style: TextStyle(
                                         fontWeight: FontWeight.w900, 
                                         fontSize: 15,
                                         color: textColor)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 40, color: dividerColor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text(s.actualSpent,
                                     style: TextStyle(
                                         fontSize: 11,
                                         color: textSubColor,
                                         fontWeight: FontWeight.bold,
                                         letterSpacing: 0.5)),
                                 const SizedBox(height: 4),
                                 Text(fmt.format(plan.currentSpent),
                                     style: TextStyle(
                                         fontWeight: FontWeight.w900,
                                         fontSize: 15,
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
                          cs, isDark),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTypeTag(
      BuildContext context, dynamic type, bool isDark, AppStrings s) {
    IconData icon;
    switch (type) {
      case PlanType.event: icon = Icons.celebration_rounded; break;
      case PlanType.living: icon = Icons.home_rounded; break;
      default: icon = Icons.flight_takeoff_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(s.getPlanTypeName(type).toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0)),
        ],
      ),
    );
  }

   Widget _buildStatusIndicator(BudgetPlan plan, AppStrings s, bool isDark) {
    if (plan.startDate == null) return const SizedBox();
    
    final diff = UIHelpers.getDaysDifference(plan.startDate!);
    final bool isOngoing = diff < 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOngoing)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent,
                  boxShadow: [
                    BoxShadow(color: Colors.greenAccent.withValues(alpha: _pulseController.value * 0.8), blurRadius: 8 * _pulseController.value, spreadRadius: 4 * _pulseController.value)
                  ],
                ),
              ),
            )
          else
            const Icon(Icons.schedule_rounded, size: 10, color: Colors.white70),
          const SizedBox(width: 6),
          Text(DateFormat('dd/MM/yyyy').format(plan.startDate!), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCountdown(BudgetPlan plan, AppStrings s, bool isDark) {
    if (plan.startDate == null) return const SizedBox();
    final diff = UIHelpers.getDaysDifference(plan.startDate!);

    String text = "";
    IconData? icon;
    Color color = Colors.white;

    if (diff == 0) {
      text = s.startsTodayLabel;
      icon = Icons.local_fire_department_rounded;
      color = Colors.orangeAccent;
    } else if (diff > 0 && diff <= 7) {
      text = s.daysRemainingLabel(diff);
      icon = Icons.hourglass_top_rounded;
    } else if (diff < 0) {
      text = s.ongoingLabel;
      color = Colors.greenAccent;
    } else {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, ColorScheme cs, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(),
            Text('${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            color: progress > 1 ? Colors.redAccent : cs.primary,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
