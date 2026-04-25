import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../ui_helpers.dart';
import 'add_transaction_modal.dart';
import 'settlement_screen.dart';
import '../group_management_screen.dart';
import '../widgets/common_widgets.dart';
import 'widgets/billshare_stats.dart';
import 'widgets/billshare_settle_card.dart';
import 'widgets/transaction_widgets.dart';
import 'widgets/member_widgets.dart';
import '../widgets/modals/member_modals.dart';

class BillShareScreen extends StatefulWidget {
  const BillShareScreen({super.key});

  @override
  State<BillShareScreen> createState() => _BillShareScreenState();
}

class _BillShareScreenState extends State<BillShareScreen> {
  int _selectedTab = 0; // 0: Expenses, 1: Payments

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    final group = state.activeSettlementGroup;
    final transactions = group?.groupTransactions ?? [];
    final people = group?.people ?? [];
    final settlements = state.getSettlementsForGroup(group);
    final hasPendingConfirmations = state.hasPendingConfirmationsForGroup(group);

    final filteredTxs = transactions.where((t) {
      final isActuallyPayment =
          t.isPayment || t.description.startsWith('Settle:');
      return _selectedTab == 0 ? !isActuallyPayment : isActuallyPayment;
    }).toList();
    final groupedTx = _groupByDate(filteredTxs, s);

    if (state.isLoading) {
      return const LoadingSkeleton();
    }
    return MainScreenScaffold(
      centerTitle: false,
      titleWidget: _buildTitle(context, group?.name ?? s.none, cs, isDark),
      fab: people.isEmpty
          ? null
          : DashboardFAB(
              enabled: people.isNotEmpty,
              label: s.addExpense,
              cs: cs,
              onTap: () => _openAddTransaction(context)),
      appBarActions: [],
      children: [
        BillShareStatsCard(
          memberCount: people.length,
          weekly: state.getWeeklyGroupTotalForGroup(group),
          monthly: state.getMonthlyGroupTotalForGroup(group),
          s: s,
          fmt: fmt,
        ),
        const SizedBox(height: 16),
        _buildMembersSection(context, state, group, s, isDark, cs),
        const SizedBox(height: 16),
        if (settlements.isNotEmpty || hasPendingConfirmations) ...[
          SettleUpCard(
            settlements: settlements,
            hasPendingConfirmations: hasPendingConfirmations,
            s: s,
            fmt: fmt,
            onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettlementScreen()))
                .then((_) => setState(() => _selectedTab = 0)),
          ),
          const SizedBox(height: 16),
        ],
        _buildTabSwitcher(state, group, s, isDark, cs),
        const SizedBox(height: 16),
        _buildTransactionList(
            filteredTxs, groupedTx, people, s, isDark, cs, fmt),
      ],
    );
  }

  Widget _buildTitle(
      BuildContext context, String groupName, ColorScheme cs, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupManagementScreen()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
              child: Text(groupName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ))),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: cs.primary),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, AppState state, Group? group,
      AppStrings s, bool isDark, ColorScheme cs) {
    final isOwner = state.currentUser?.uid == group?.ownerId;
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SectionLabel(label: s.members, icon: Icons.people_alt_rounded),
          if (isOwner)
            ActionIconButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (group != null) state.switchGroup(group.id);
                  showAddMember(context, s);
                },
                isDark: isDark),
        ],
      ),
      const SizedBox(height: 12),
      MemberSection(
          people: group?.people ?? [],
          netBalances: state.getNetBalancesForGroup(group),
          paidBalances: state.getPaidBalancesForGroup(group),
          shareBalances: state.getShareBalancesForGroup(group),
          s: s,
          cs: cs),
    ]);
  }

  Widget _buildTabSwitcher(
      AppState state, Group? group, AppStrings s, bool isDark, ColorScheme cs) {
    final settlements = state.getSettlementsForGroup(group);
    final hasPendingTxs = group?.groupTransactions.any((t) => t.status == TransactionStatus.pending) ?? false;
    final canClearHistory = settlements.isEmpty && !hasPendingTxs;
    
    return Row(
      children: [
        Expanded(
            child: SectionLabel(
                label: _selectedTab == 0 ? s.tabPay : s.tabBill,
                icon: Icons.sort_rounded)),
        Opacity(
          opacity: canClearHistory ? 1.0 : 0.4,
          child: ActionIconButton(
              icon: Icons.cleaning_services_rounded,
              onTap: canClearHistory
                  ? () {
                      if (group != null) state.switchGroup(group.id);
                      _confirmClearHistory(context, s);
                    }
                  : () {},
              isDark: isDark),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HistoryTab(
                  label: s.tabPay,
                  active: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                  isDark: isDark,
                  cs: cs),
              HistoryTab(
                  label: s.tabBill,
                  active: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                  isDark: isDark,
                  cs: cs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(
      List<GroupTransaction> filteredTxs,
      Map<DateTime, List<GroupTransaction>> groupedTx,
      List<Person> people,
      AppStrings s,
      bool isDark,
      ColorScheme cs,
      NumberFormat fmt) {
    if (filteredTxs.isEmpty) {
      return EmptyCard(
          icon:
              _selectedTab == 0 ? Icons.coffee_rounded : Icons.payments_rounded,
          message: s.noExpenses);
    }
    final sortedKeys = groupedTx.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedKeys
          .map((date) => DateGroup(
              date: date,
              transactions: groupedTx[date]!,
              people: people,
              fmt: fmt,
              s: s))
          .toList(),
    );
  }

  void _openAddTransaction(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTransactionModal()).then((_) {
      if (mounted) setState(() => _selectedTab = 0);
    });
  }

  Map<DateTime, List<GroupTransaction>> _groupByDate(
      List<GroupTransaction> txs, AppStrings s) {
    final sorted = [...txs]..sort((a, b) => b.date.compareTo(a.date));
    final map = <DateTime, List<GroupTransaction>>{};
    for (final tx in sorted) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      map.putIfAbsent(date, () => []).add(tx);
    }
    return map;
  }

  void _confirmClearHistory(BuildContext context, AppStrings s) {
    UIHelpers.showLiquidDialog(
      context: context,
      title: s.clearHistory,
      content: Text(s.clearHistoryMsg),
      confirmLabel: s.clearHistory,
      isDestructive: true,
      onConfirm: () async {
        await context.read<AppState>().clearExpenses();
      },
    );
  }
}
