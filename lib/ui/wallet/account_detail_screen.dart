import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../widgets/common_widgets.dart';
import '../ui_helpers.dart';
import '../ledger/widgets/simple_transaction_modal.dart';
import '../billshare/add_transaction_modal.dart';
import '../ledger/widgets/transaction_detail_modal.dart';
import 'add_account_modal.dart';

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
    final accountFlow = state.allTransactions.where((t) {
      if (t.sourceAccountId == account.id) {
        return true;
      }
      if (t is GroupTransaction &&
          t.participantBalances?.containsValue(account.id) == true) {
        return true;
      }
      return false;
    }).toList();

    // Listen for account updates to refresh the UI
    final currentAccount = state.accounts.firstWhere((a) => a.id == account.id, orElse: () => account);

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
                      _buildAppBar(context, currentAccount, isDark),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildBalanceHeader(currentAccount, s, fmt, isDark),
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
                                child: _buildGroupedHistory(
                                    context, accountFlow, fmt, isDark),
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

  Widget _buildAppBar(BuildContext context, Account acc, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () => AddAccountModal.show(context, initialAccount: acc),
          icon: Icon(Icons.edit_note_rounded, 
                     color: isDark ? Colors.white70 : Colors.black54),
        ),
        const SizedBox(width: 8),
      ],
      title: Text(
        acc.name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(Account acc, AppStrings s, NumberFormat fmt, bool isDark) {
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
            fmt.format(acc.currentBalance),
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
              acc.type.name.toUpperCase(),
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

    final runningBalances = <String, double>{};
    double currentBal = account.currentBalance;
    for (var i = 0; i < accountFlow.length; i++) {
        final tx = accountFlow[i];
        runningBalances[tx.id] = currentBal;
        
        bool txIsOutgoing = tx.sourceAccountId == account.id;
        if (tx is PersonalTransaction && tx.isPayment) txIsOutgoing = false; // Income
        if (tx is GroupTransaction && tx.isPayment && tx.participantBalances?.containsValue(account.id) == true) txIsOutgoing = false; // Recipient
        
        currentBal += (txIsOutgoing ? tx.amount : -tx.amount);
    }

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
            ...txs.map((tx) => _buildFlowItem(context, tx, fmt, isDark, runningBalances[tx.id] ?? 0)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFlowItem(BuildContext context, BaseTransaction tx, NumberFormat fmt, bool isDark, double balanceAfter) {
    final s = AppStrings.of(context);
    final state = context.read<AppState>();
    
    bool isOutgoing = tx.sourceAccountId == account.id;
    if (tx is PersonalTransaction && tx.isPayment) {
      isOutgoing = false; // Personal Income
    }
    if (tx is GroupTransaction &&
        tx.isPayment &&
        tx.participantBalances?.containsValue(account.id) == true) {
      isOutgoing = false; // Linked settlement recipient
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransactionActions(context, state, tx, s),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isOutgoing ? "-" : "+"}${fmt.format(tx.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isOutgoing
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.green,
                          ),
                        ),
                        Text(
                          'Balance: ${fmt.format(balanceAfter)}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      ],
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

  void _showTransactionActions(BuildContext context, AppState state, BaseTransaction tx, AppStrings s) {
    HapticFeedback.lightImpact();
    
    // Permission check for shared transactions
    bool isLockedGroup = tx is GroupTransaction && !tx.isPayment && state.hasSettlements;
    bool isShared = false;

    // Determine if it's billshare-linked
    if (tx is GroupTransaction) {
      isShared = true;
    } else if (tx is PersonalTransaction) {
      if (tx.id.startsWith('p_') || tx.isShared || tx.groupId != null) {
        isShared = true;
      }
    }

    // Shared logic: In this screen, shared transactions are ALWAYS READ-ONLY for editing
    // because you cannot manage participant splits from the personal ledger.
    // However, users CAN delete them from their personal history independently.
    final canEdit = !isShared && !isLockedGroup;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isShared)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Shared transaction. To edit group splits or participants, please use the BillShare tab.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isLockedGroup)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Settlements in progress. Clear all settlements before editing expenses.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(s.viewDetails),
              onTap: () {
                Navigator.pop(ctx);
                _showTransactionDetail(context, tx);
              },
            ),
            Opacity(
              opacity: canEdit ? 1.0 : 0.3,
              child: ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(s.edit),
                onTap: !canEdit
                    ? null
                    : () {
                        Navigator.pop(ctx);
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
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(s.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, state, tx, s);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, BaseTransaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TransactionDetailModal(tx: tx),
    );
  }
}
