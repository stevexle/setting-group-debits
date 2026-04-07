import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../models/transaction.dart';
import '../../l10n/strings.dart';
import '../widgets/common_widgets.dart';
import '../widgets/elements/options_sheet.dart';
import 'widgets/simple_transaction_modal.dart';
import 'widgets/transaction_detail_modal.dart';
import '../billshare/add_transaction_modal.dart';
import '../wallet/wallet_screen.dart';
import '../ui_helpers.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final fmt =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    final cashFlow = state.transactions;

    return MainScreenScaffold(
      title: s.navLedger.toUpperCase(),
      appBarBottom: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(text: s.tabMovement),
          Tab(text: s.tabAnalysis),
        ],
      ),
      fab: DashboardFAB(
        enabled: state.accounts.isNotEmpty,
        label: s.addTransaction,
        cs: cs,
        onTap: () => _showAddTransaction(context),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(context, cashFlow, fmt, isDark, state),
          _buildAnalysisTab(context, fmt, isDark, state),
        ],
      ),
      children: const [],
    );
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SimpleTransactionModal(),
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<BaseTransaction> cashFlow,
      NumberFormat fmt, bool isDark, AppState state) {
    final s = AppStrings.of(context);
    if (cashFlow.isEmpty) {
      return Center(
        child: EmptyCard(
          message: s.noCashFlow,
          icon: Icons.receipt_rounded,
        ),
      );
    }

    final grouped = UIHelpers.groupTransactionsByMonth(cashFlow);
    final monthKeys = grouped.keys.toList();

    final runningBalances = <String, double>{};
    double currentBal = state.totalNetWorth;
    for (var i = 0; i < cashFlow.length; i++) {
      final tx = cashFlow[i];
      runningBalances[tx.id] = currentBal;
      
      bool isNegative = !tx.isPayment;
      if (tx is GroupTransaction && tx.isPayment) {
        isNegative = tx.payerId == (state.me?.id ?? '');
      }
      
      currentBal += (isNegative ? tx.amount : -tx.amount);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: monthKeys.length,
      itemBuilder: (context, mIdx) {
        final monthKey = monthKeys[mIdx];
        final txs = grouped[monthKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
            ...txs.map((tx) => _buildCashFlowItem(context, tx, fmt, isDark, runningBalances[tx.id] ?? 0)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildAnalysisTab(
      BuildContext context, NumberFormat fmt, bool isDark, AppState state) {
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    final income = state.allTransactions
        .where((t) => t.isPayment)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = state.monthlyPersonalTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildChartOverview(context, state, isDark),
          const SizedBox(height: 24),
          SummaryActionCard(
            title: s.analysisOverview.toUpperCase(),
            actionLabel: s.viewWallet.toUpperCase(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
            gradientColors: [
              cs.primary.withValues(alpha: 0.1),
              Colors.orangeAccent.withValues(alpha: 0.05),
            ],
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: _buildStat(s.incomeLabel, fmt.format(income), Colors.green)),
                  Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.05)),
                  Expanded(
                      child:
                          _buildStat(s.expenseLabel, fmt.format(expense), Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      size: 14, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    '${s.netBalanceLabel}${fmt.format(income - expense)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: (income - expense) >= 0 ? Colors.green : Colors.redAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCategoryBreakdown(context, state, fmt, isDark),
        ],
      ),
    );
  }

  Widget _buildChartOverview(BuildContext context, AppState state, bool isDark) {
    final categoryMap = state.categorySpend;
    if (categoryMap.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: categoryMap.entries.map((e) {
              final color = UIHelpers.getCategoryColor(e.key);
              return PieChartSectionData(
                color: color,
                value: e.value,
                title: '',
                radius: 50,
                badgeWidget: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Icon(UIHelpers.getCategoryIcon(e.key), size: 12, color: color),
                ),
                badgePositionPercentageOffset: 0.98,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, AppState state, NumberFormat fmt, bool isDark) {
    final categoryMap = state.categorySpend;
    if (categoryMap.isEmpty) return const SizedBox.shrink();
    final s = AppStrings.of(context);

    final sortedEntries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            s.categoryBreakdown,
            style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white54 : Colors.black54),
          ),
        ),
        ...sortedEntries.map((e) {
          final totalExpense = state.allTransactions
              .where((t) => !t.isPayment)
              .fold(0.01, (sum, t) => sum + t.amount);
          final percent = e.value / totalExpense;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CategoryIcon(category: e.key, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppStrings.of(context).getCategoryName(e.key),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${(percent * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            color: UIHelpers.getCategoryColor(e.key),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(fmt.format(e.value),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
                style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            )),
      ],
    );
  }

  Widget _buildCashFlowItem(
      BuildContext context, BaseTransaction tx, NumberFormat fmt, bool isDark, double balanceAfter) {
    final s = AppStrings.of(context);
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: Dismissible(
          key: Key(tx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_sweep_rounded,
                color: Colors.white, size: 24),
          ),
          confirmDismiss: (_) async {
            bool isPendingSettlement = tx is GroupTransaction && tx.isPayment && tx.status == TransactionStatus.pending;
            bool isLockedExpense = tx is GroupTransaction && !tx.isPayment && state.hasSettlements;

            if (isPendingSettlement || isLockedExpense) {
              _confirmDelete(context, state, tx, s);
              return false;
            }
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(s.deleteExpense, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                content: Text(s.deleteExpenseMsg, style: const TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel, style: const TextStyle(color: Colors.white38))),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.delete, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            if (tx is GroupTransaction) {
              state.removeGroupTransaction(tx.id);
            } else if (tx is PersonalTransaction) {
              state.removePersonalTransaction(tx.id);
            }
          },
          child: InkWell(
            onTap: () => _showTransactionOptions(context, state, tx, s),
            onLongPress: () => _confirmDelete(context, state, tx, s),
            borderRadius: BorderRadius.circular(20),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CategoryIcon(category: tx.category, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          UIHelpers.formatSmartDate(tx.date, s),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Builder(builder: (context) {
                        bool isNegative = !tx.isPayment;
                        if (tx is GroupTransaction && tx.isPayment) {
                          isNegative = tx.payerId == (state.me?.id ?? '');
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isNegative ? "-" : "+"}${fmt.format(tx.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isNegative
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
                        );
                      }),
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
      ),
    );
  }

  void _showTransactionOptions(BuildContext context, AppState state, BaseTransaction tx, AppStrings s) {
    final myPersonIds = state.myPersonIds;
    bool isLockedGroup = tx is GroupTransaction && !tx.isPayment && state.hasSettlements;
    bool isShared = false;
    bool isPayer = true;

    if (tx is GroupTransaction) {
      isShared = true;
      isPayer = myPersonIds.contains(tx.payerId);
    } else if (tx is PersonalTransaction) {
      if (tx.id.startsWith('p_') || tx.isShared || tx.groupId != null) {
        isShared = true;
        isPayer = tx.payerId != null && myPersonIds.contains(tx.payerId);
      }
    }

    // Shared items are READ-ONLY in the Ledger to prevent split inconsistencies
    // forcing the user to use BillShare for editing.
    final canEdit = !isShared && isPayer && !isLockedGroup;
    final canDelete = true; // Always allow local history cleanup

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppOptionsSheet(
        title: s.chooseAction,
        message: (isShared) 
          ? "Shared transaction. To edit group splits or participants, please use the BillShare tab."
          : (isLockedGroup ? "Settlements in progress. Clear all settlements before editing expenses." : null),
        messageColor: isShared ? Colors.blue : Colors.amber,
        options: [
          AppOption(
            label: s.viewDetails,
            icon: Icons.info_outline_rounded,
            onTap: () {
              Navigator.pop(ctx);
              _showTransactionDetail(context, tx);
            },
          ),
          AppOption(
            label: s.edit,
            icon: Icons.edit_rounded,
            enabled: canEdit,
            onTap: () {
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
          AppOption(
            label: s.delete,
            icon: Icons.delete_rounded,
            isDestructive: true,
            enabled: canDelete,
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, state, tx, s);
            },
          ),
        ],
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, BaseTransaction tx) {
    // Basic detail view for now
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TransactionDetailModal(tx: tx),
    );
  }

  void _confirmDelete(
      BuildContext context, AppState state, BaseTransaction tx, AppStrings s) {
    bool isPendingSettlement = tx is GroupTransaction && tx.isPayment && tx.status == TransactionStatus.pending;
    bool isLockedExpense = tx is GroupTransaction && !tx.isPayment && state.hasSettlements;

    if (isPendingSettlement || isLockedExpense) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isPendingSettlement ? s.settlement.toUpperCase() : "LOCKED",
              style: TextStyle(fontWeight: FontWeight.w900, color: isPendingSettlement ? Colors.orangeAccent : Colors.amber)),
          content: Text(
            isPendingSettlement 
              ? "This settlement transaction is still pending. Please wait for the recipient to Confirm or Reject before deleting."
              : "Settlements are in progress for this group. Please clear or complete all settlements before deleting or editing shared expenses.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.done.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

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
