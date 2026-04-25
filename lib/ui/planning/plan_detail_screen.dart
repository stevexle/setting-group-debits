import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../widgets/common_widgets.dart';
import '../widgets/modals/member_modals.dart';

import 'edit_plan_screen.dart';
import 'add_itinerary_screen.dart';
import 'edit_itinerary_screen.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';

import 'widgets/plan_overview_tab.dart';
import 'widgets/plan_itinerary_tab.dart';
import 'widgets/plan_checklist_tab.dart';
import 'widgets/plan_distribution_tab.dart';
import 'widgets/plan_modals.dart';
import '../ledger/widgets/simple_transaction_modal.dart';

class PlanDetailScreen extends StatefulWidget {
  final BudgetPlan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    // Always get the latest plan from state to avoid stale data
    BudgetPlan? currentPlan;
    try {
      // Search in groups
      for (final g in state.groups) {
        final p = g.plans.where((p) => p.id == widget.plan.id).firstOrNull;
        if (p != null) {
          currentPlan = p;
          break;
        }
      }
      // If not in groups, check root
      currentPlan ??= state.plans.where((p) => p.id == widget.plan.id).firstOrNull;
    } catch (_) {}

    // Fallback to widget.plan if not found (shouldn't happen unless deleted)
    final plan = currentPlan ?? widget.plan;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final s = AppStrings.of(context);

    // Associated transactions
    final planTxs = state.personalTransactions
        .where((t) => t.planId == plan.id)
        .toList();

    final group = state.groups.where((g) => g.id == plan.linkedGroupId).firstOrNull;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      body: Stack(
        children: [
          const Positioned.fill(child: LiquidBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, plan, isDark, s),
                _buildTabs(s, isDark, plan.type),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      PlanOverviewTab(
                        plan: plan,
                        txs: planTxs,
                        fmt: fmt,
                        isDark: isDark,
                        s: s,
                        linkedGroup: group,
                        onEditPlan: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditPlanScreen(plan: plan))),
                        onDeletePlan: () => confirmDeletePlan(context, s, plan),
                        onAddMember: () {
                          state.switchGroup(group?.id ?? '');
                          showAddMember(context, s);
                        },
                      ),
                      plan.type == PlanType.living
                        ? PlanDistributionTab(plan: plan, fmt: fmt, isDark: isDark, s: s)
                        : PlanItineraryTab(
                            plan: plan, 
                            fmt: fmt, 
                            isDark: isDark, 
                            s: s, 
                            onEdit: (item) => Navigator.push(context, MaterialPageRoute(builder: (_) => EditItineraryScreen(plan: plan, item: item))),
                            onAddSpend: (item) => _showAddSpendModal(context, item.activity, item.estimatedCost, plan.id),
                          ),
                      PlanChecklistTab(
                        plan: plan, 
                        fmt: fmt, 
                        isDark: isDark, 
                        s: s, 
                        onToggleTask: (ctx, task, s) => onToggleTask(ctx, task, s, plan),
                        onEdit: (task) => Navigator.push(context, MaterialPageRoute(builder: (_) => EditTaskScreen(plan: plan, task: task))),
                        onAddSpend: (task) => _showAddSpendModal(context, task.title, task.estimatedCost, plan.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context, plan, s),
    );
  }

  void _showAddSpendModal(BuildContext context, String description, double amount, String planId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SimpleTransactionModal(
        initialTransaction: PersonalTransaction(
          description: description,
          amount: amount,
          date: DateTime.now(),
          category: Category.other,
          payerId: '', // Filled by modal
          planId: planId,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BudgetPlan plan, bool isDark, AppStrings s) {
    final state = context.watch<AppState>();
    Group? linkedGroup;
    if (plan.linkedGroupId != null) {
      final groups = state.groups.where((g) => g.id == plan.linkedGroupId);
      if (groups.isNotEmpty) linkedGroup = groups.first;
    }

    final accentColor = _getPlanAccentColor(plan.type);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${plan.itinerary.length} ${s.tabItinerary.toLowerCase()} • ${plan.checklist.length} ${s.tabChecklist.toLowerCase()}",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (linkedGroup != null)
                _buildAvatarsStack(linkedGroup, isDark)
              else
                IconButton(
                  icon: Icon(Icons.settings_input_composite_rounded,
                      size: 20, color: isDark ? Colors.white38 : Colors.black38),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditPlanScreen(plan: plan))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPlanAccentColor(PlanType type) {
    switch (type) {
      case PlanType.trip: return Colors.blueAccent;
      case PlanType.living: return Colors.greenAccent;
      case PlanType.event: return Colors.purpleAccent;
      case PlanType.other: return Colors.orangeAccent;
    }
  }

  Widget _buildAvatarsStack(Group group, bool isDark) {
    if (group.people.isEmpty) return const SizedBox();
    final maxToShow = 3;
    final displayPeople = group.people.take(maxToShow).toList();
    final rem = group.people.length - maxToShow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32.0 + (displayPeople.length - 1) * 20.0 + (rem > 0 ? 20.0 : 0.0),
          height: 32,
          child: Stack(
            children: [
              for (int i = 0; i < displayPeople.length; i++)
                Positioned(
                  left: i * 20.0,
                  child: GestureDetector(
                    onTap: () {
                      final p = displayPeople[i];
                      showPersonSummary(
                          context,
                          p,
                          0,
                          0,
                          0,
                          AppStrings.of(context),
                          NumberFormat.currency(
                              locale: 'vi_VN', symbol: '₫', decimalDigits: 0),
                          hideStats: true);
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.primaries[displayPeople[i].colorIndex % Colors.primaries.length],
                        child: Text(displayPeople[i].name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              if (rem > 0)
                Positioned(
                  left: displayPeople.length * 20.0,
                  child: GestureDetector(
                    onTap: () => _showAllMembersModal(context, group, isDark),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                        child: Text('+$rem', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            context.read<AppState>().switchGroup(group.id);
            showAddMember(context, AppStrings.of(context));
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.person_add_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
          ),
        )
      ],
    );
  }

  void _showAllMembersModal(BuildContext context, Group group, bool isDark) {
    final s = AppStrings.of(context);
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
            Text(s.navGroups.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: Colors.grey)),
            const SizedBox(height: 16),
            ...group.people.map((p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.primaries[p.colorIndex % Colors.primaries.length],
                child: Text(p.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: p.accountNo != null ? Text(p.accountNo!) : null,
              onTap: () {
                Navigator.pop(ctx);
                showPersonSummary(context, p, 0, 0, 0, s, NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0));
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(AppStrings s, bool isDark, PlanType type) {
    return TabBar(
      controller: _tabController,
      indicatorColor: Theme.of(context).colorScheme.primary,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      tabs: [
        Tab(text: type == PlanType.living ? "MỤC TIÊU" : s.tabOverview),
        Tab(text: type == PlanType.living ? "PHÂN BỔ" : s.tabItinerary),
        Tab(text: s.tabChecklist),
      ],
    );
  }


  Widget? _buildFab(BuildContext context, BudgetPlan plan, AppStrings s) {
    // Show FAB for Itinerary and Checklist tabs
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
        if (_tabController.index == 0) return const SizedBox();
        return FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 1) {
              if (plan.type == PlanType.living) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(plan: plan)));
              } else {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => AddItineraryScreen(plan: plan)));
              }
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(plan: plan)));
            }
          },
          label: Text(_tabController.index == 1 
            ? (plan.type == PlanType.living ? s.addTask : s.addItinerary) 
            : s.addTask),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        );
      },
    );
  }

}
