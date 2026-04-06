import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../widgets/common_widgets.dart';

class PlanDetailScreen extends StatelessWidget {
  final BudgetPlan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    // Associated transactions for this specific plan
    final planTxs =
        state.personalTransactions.where((t) => t.planId == plan.id).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      body: Stack(
        children: [
          const Positioned.fill(child: LiquidBackground()),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: isWide ? 800 : constraints.maxWidth,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(context, isDark),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildBudgetHeader(fmt, cs, isDark, s),
                        ),
                      ),
                      if (plan.referenceLinks.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: SectionLabel(
                            label: s.referencesLabel,
                            icon: Icons.link_rounded,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _buildLinksSection(isDark, s),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: SectionLabel(
                          label: s.planExpensesLabel,
                          icon: Icons.receipt_long_rounded,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: planTxs.isEmpty
                            ? SliverToBoxAdapter(
                                child: EmptyCard(
                                  message: s.noExpensesForPlan,
                                  icon: Icons.money_off_rounded,
                                ),
                              )
                            : SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400,
                                  mainAxisExtent: 80,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildTransactionItem(
                                      planTxs[index], fmt, isDark),
                                  childCount: planTxs.length,
                                ),
                              ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      title: Text(
        plan.title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBudgetHeader(
      NumberFormat fmt, ColorScheme cs, bool isDark, AppStrings s) {
    final progress =
        plan.currentSpent / (plan.budgetTotal > 0 ? plan.budgetTotal : 1);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetItem(
                  s.estimatedBudget, fmt.format(plan.budgetTotal), isDark, s),
              _buildBudgetItem(
                  s.actualSpent, fmt.format(plan.currentSpent), isDark, s,
                  color: Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            s.budgetProgress,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white54 : Colors.black45,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: progress > 1 ? Colors.redAccent : cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: progress > 1 ? Colors.redAccent : cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(String label, String value, bool isDark, AppStrings s,
      {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white54,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color ?? (isDark ? Colors.white : Colors.black87),
            )),
      ],
    );
  }

  Widget _buildLinksSection(bool isDark, AppStrings s) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: plan.referenceLinks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.play_circle_fill_rounded,
                  size: 16, color: Colors.blueAccent),
              label: Text(
                '${s.linkReview} #${index + 1}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // TODO: Open Link
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(PersonalTransaction tx, NumberFormat fmt, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CategoryIcon(category: tx.category, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    DateFormat('dd/MM HH:mm').format(tx.date),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
            Text(
              '-${fmt.format(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
