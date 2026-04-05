import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../widgets/common_widgets.dart';
import '../ui_helpers.dart';
import '../ledger/widgets/simple_transaction_modal.dart';
import '../billshare/add_transaction_modal.dart';

class AccountDetailScreen extends StatelessWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    // Filter transactions that belong to this account
    final accountFlow =
        state.allTransactions.where((t) => t.sourceAccountId == account.id).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      body: Stack(
        children: [
          const LiquidBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildBalanceHeader(s, fmt, isDark),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionLabel(
                  label: s.historyLabel,
                  icon: Icons.history_rounded,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: accountFlow.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyCard(
                          message: s.noHistoryForAccount,
                          icon: Icons.history_edu_rounded,
                        ),
                      )
                    : SliverToBoxAdapter(
                        child: _buildGroupedHistory(context, accountFlow, fmt, isDark),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
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
        account.name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(AppStrings s, NumberFormat fmt, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      gradientColors: [
        Colors.blue.withValues(alpha: 0.1),
        Colors.indigo.withValues(alpha: 0.05),
      ],
      child: Column(
        children: [
          Text(
            s.currentBalanceLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white54 : Colors.black45,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(account.currentBalance),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              account.type.name.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedHistory(BuildContext context, List<BaseTransaction> accountFlow, NumberFormat fmt, bool isDark) {
    final grouped = UIHelpers.groupTransactionsByMonth(accountFlow);
    final monthKeys = grouped.keys.toList();

    return Column(
      children: monthKeys.map((monthKey) {
        final txs = grouped[monthKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 16, 12),
              child: Text(
                monthKey.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white54 : Colors.black45,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ...txs.map((tx) => _buildFlowItem(context, tx, fmt, isDark)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFlowItem(BuildContext context, BaseTransaction tx, NumberFormat fmt, bool isDark) {
    final s = AppStrings.of(context);
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (tx is PersonalTransaction) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => SimpleTransactionModal(initialTransaction: tx),
              );
            } else if (tx is GroupTransaction) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => AddTransactionModal(initialTransaction: tx),
              );
            }
          },
          onLongPress: () => _confirmDelete(context, state, tx, s),
          borderRadius: BorderRadius.circular(20),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CategoryIcon(category: tx.category, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.description,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        UIHelpers.formatSmartDate(tx.date, s),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${tx.isPayment ? "+" : "-"}${fmt.format(tx.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: tx.isPayment
                            ? Colors.green
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (tx is PersonalTransaction && tx.planId != null)
                      Text(
                        s.inPlan,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, BaseTransaction tx, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.deleteExpense,
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        content: Text(s.deleteExpenseMsg,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: const TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              if (tx is GroupTransaction) {
                state.removeGroupTransaction(tx.id);
              } else if (tx is PersonalTransaction) {
                state.removePersonalTransaction(tx.id);
              }
              Navigator.pop(ctx);
            },
            child: Text(s.delete,
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
