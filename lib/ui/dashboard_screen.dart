import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../l10n/strings.dart';
import 'ui_helpers.dart';
import 'add_transaction_modal.dart';
import 'settlement_screen.dart';
import 'group_management_screen.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0; // 0: Expenses, 1: Payments

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    final filteredTxs = state.transactions.where((t) {
      final isActuallyPayment =
          t.isPayment || t.description.startsWith('Settle:');
      return _selectedTab == 0 ? !isActuallyPayment : isActuallyPayment;
    }).toList();
    final groupedTx = _groupByDate(filteredTxs, s);

    if (state.isLoading) {
      return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
          body: const LoadingSkeleton());
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      floatingActionButton: state.people.isEmpty
          ? null
          : DashboardFAB(
              enabled: state.people.isNotEmpty,
              label: s.addExpense,
              cs: cs,
              onTap: () => _openAddTransaction(context)),
      body: Stack(
        children: [
          const LiquidBackground(),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final horizontalPadding = isWide ? constraints.maxWidth * 0.1 : 12.0;
              final titleSize = isWide ? 42.0 : 32.0;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context, state, s, isDark, cs),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 10),
                        DashboardStatsCard(
                          memberCount: state.people.length,
                          weekly: state.weeklyTotal,
                          monthly: state.monthlyTotal,
                          s: s,
                          fmt: fmt,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'BillShare',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              fontFamily: 'Outfit',
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildMembersSection(context, state, s, isDark, cs),
                        const SizedBox(height: 16),
                        if (state.settlements.isNotEmpty) ...[
                          SettleUpCard(
                            settlements: state.settlements,
                            s: s,
                            fmt: fmt,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettlementScreen())).then((_) => setState(() => _selectedTab = 1)),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildTabSwitcher(state, s, isDark, cs),
                        const SizedBox(height: 16),
                        _buildTransactionList(filteredTxs, groupedTx, state, s, isDark, cs, fmt),
                        const SizedBox(height: 120),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppState state, AppStrings s, bool isDark, ColorScheme cs) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GroupManagementScreen()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
                child: Text(state.groupName,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontFamily: 'Outfit'))),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: cs.primary),
          ],
        ),
      ),
      actions: [
        _buildUserAvatar(state, cs, s),
        const SizedBox(width: 8),
        ActionIconButton(
            icon: Icons.refresh_rounded, 
            onTap: () => _confirmResetGroup(context, s),
            isDark: isDark),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildUserAvatar(AppState state, ColorScheme cs, AppStrings s) {
    return GestureDetector(
      onTap: () => _showUserDialog(state, s),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
          image: state.currentUser?.photoURL != null
              ? DecorationImage(image: NetworkImage(state.currentUser!.photoURL!), fit: BoxFit.cover)
              : null,
        ),
        child: state.currentUser?.photoURL == null
            ? Center(
                child: Text((state.currentUser?.displayName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 10)))
            : null,
      ),
    );
  }

  void _showUserDialog(AppState state, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.currentUser?.displayName ?? 'User'),
        content: Text(state.currentUser?.email ?? ''),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                state.signOut();
              },
              child: Text(s.logout, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, AppState state, AppStrings s, bool isDark, ColorScheme cs) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SectionLabel(label: s.members, icon: Icons.people_alt_rounded),
          ActionIconButton(icon: Icons.add_rounded, onTap: () => showAddMember(context, s), isDark: isDark),
        ],
      ),
      const SizedBox(height: 12),
      MemberSection(
          people: state.people,
          netBalances: state.netBalances,
          paidBalances: state.paidBalances,
          shareBalances: state.shareBalances,
          s: s,
          cs: cs),
    ]);
  }

  Widget _buildTabSwitcher(AppState state, AppStrings s, bool isDark, ColorScheme cs) {
    // Safety logic for Clear History button
    final canClearHistory = state.settlements.isEmpty || !state.hasSettlements;

    return Row(
      children: [
        Expanded(child: SectionLabel(label: _selectedTab == 0 ? s.tabPay : s.tabBill, icon: Icons.sort_rounded)),
        Opacity(
          opacity: canClearHistory ? 1.0 : 0.4,
          child: ActionIconButton(
            icon: Icons.cleaning_services_rounded,
            onTap: canClearHistory 
              ? () => _confirmClearHistory(context, s)
              : () => UIHelpers.showLiquidDialog(
                  context: context, 
                  title: s.cannotClear, 
                  content: Text(s.completeSettlementFirst),
                  confirmLabel: s.understood,
                  onConfirm: () {},
                ),
            isDark: isDark),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HistoryTab(label: s.tabPay, active: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0), isDark: isDark, cs: cs),
              HistoryTab(label: s.tabBill, active: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1), isDark: isDark, cs: cs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<Transaction> filteredTxs, Map<DateTime, List<Transaction>> groupedTx, AppState state, AppStrings s, bool isDark, ColorScheme cs, NumberFormat fmt) {
    if (filteredTxs.isEmpty) {
      return EmptyCard(icon: _selectedTab == 0 ? Icons.coffee_rounded : Icons.payments_rounded, message: s.noExpenses);
    }
    final sortedKeys = groupedTx.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedKeys
          .map((date) => DateGroup(
              date: date,
              transactions: groupedTx[date]!,
              people: state.people,
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
        builder: (_) => const AddTransactionModal());
  }

  Map<DateTime, List<Transaction>> _groupByDate(List<Transaction> txs, AppStrings s) {
    final sorted = [...txs]..sort((a, b) => b.date.compareTo(a.date));
    final map = <DateTime, List<Transaction>>{};
    for (final tx in sorted) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      map.putIfAbsent(date, () => []).add(tx);
    }
    return map;
  }

  void _confirmResetGroup(BuildContext context, AppStrings s) {
    UIHelpers.showLiquidDialog(
      context: context,
      title: s.resetGroup,
      content: Text(s.resetGroupMsg),
      confirmLabel: s.resetGroup,
      isDestructive: true,
      onConfirm: () async {
        await context.read<AppState>().clearAll();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.groupResetSuccess)));
        }
      },
    );
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.historyClearedSuccess)));
        }
      },
    );
  }
}
