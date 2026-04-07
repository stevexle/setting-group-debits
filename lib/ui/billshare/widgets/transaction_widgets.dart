import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../models.dart';
import '../../../state/app_state.dart';
import '../../../l10n/strings.dart';
import '../../ui_helpers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/elements/options_sheet.dart';
import '../../ledger/widgets/transaction_detail_modal.dart';
import '../add_transaction_modal.dart';

void confirmRemoveTransaction(
    BuildContext context, GroupTransaction tx, AppStrings s) {
  final state = context.read<AppState>();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  UIHelpers.showLiquidDialog(
    context: context,
    title: s.deleteExpense,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 14),
              children: [
                TextSpan(text: '${s.delete} '),
                TextSpan(
                    text: tx.description,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '?')
              ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.deleteExpenseMsg,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w600)),
              )
            ],
          ),
        )
      ],
    ),
    confirmLabel: s.delete,
    isDestructive: true,
    onConfirm: () => state.removeGroupTransaction(tx.id),
  );
}

class TransactionCard extends StatelessWidget {
  final GroupTransaction tx;
  final List<Person> people;
  final NumberFormat fmt;
  final AppStrings s;

  const TransactionCard({
    super.key,
    required this.tx,
    required this.people,
    required this.fmt,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = UIHelpers.getCategoryColor(tx.category);
    final isEdited = tx.amountChanged && tx.updatedAt != null;

    final state = context.watch<AppState>();
    final isMeRecipient = tx.isPayment &&
        tx.status == TransactionStatus.pending &&
        tx.participants.contains(state.me?.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 24,
        border: isMeRecipient 
            ? Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 1.5)
            : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              final isCreator = state.me?.id == tx.creatorId;
              
              // Rules for locking:
              // 1. Settlement confirmed by recipient
              final isSettlementConfirmed = tx.isPayment && tx.status == TransactionStatus.confirmed;
              
              // 2. Expense before the last confirmed payment (period closing)
              bool isBeforeLatestSettlement = false;
              if (!tx.isPayment) {
                final settlements = state.groupTransactions
                  .where((t) => t.isPayment && t.status == TransactionStatus.confirmed)
                  .toList();
                if (settlements.isNotEmpty) {
                  final latest = settlements.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
                  if (tx.date.isBefore(latest.date)) {
                    isBeforeLatestSettlement = true;
                  }
                }
              }

              final isLocked = !isCreator || isSettlementConfirmed || isBeforeLatestSettlement;
              
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => AppOptionsSheet(
                  title: s.options,
                  message: !isCreator 
                      ? s.editPermissionDenied 
                      : (isLocked 
                          ? (isBeforeLatestSettlement ? s.cannotEditSettled : s.cannotEditConfirmed)
                          : null),
                  options: [
                    AppOption(
                      label: s.viewDetails,
                      icon: Icons.info_outline_rounded,
                      onTap: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => TransactionDetailModal(tx: tx),
                        );
                      },
                    ),
                    AppOption(
                      label: s.edit,
                      icon: Icons.edit_rounded,
                      enabled: isCreator && !isLocked,
                      onTap: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => AddTransactionModal(initialTransaction: tx),
                        );
                      },
                    ),
                    AppOption(
                      label: s.delete,
                      icon: Icons.delete_outline_rounded,
                      enabled: isCreator && !isLocked,
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(ctx);
                        UIHelpers.showLiquidDialog(
                          context: context,
                          title: s.deleteExpense,
                          content: Text(s.deleteExpenseMsg),
                          confirmLabel: s.delete,
                          isDestructive: true,
                          onConfirm: () => state.removeGroupTransaction(tx.id),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAvatarSection(accentColor),
                      const SizedBox(width: 16),
                      _buildContentSection(isEdited, isDark, state),
                      const SizedBox(width: 12),
                      _buildAmountSection(accentColor, isDark),
                    ],
                  ),
                  if (isMeRecipient) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: Colors.white12),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => state.rejectSettlement(tx.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(s.reject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _confirmWithAccount(context, state),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(s.confirmBalance, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmWithAccount(BuildContext context, AppState state) {
    if (state.accounts.isEmpty) {
      state.confirmSettlement(tx.id);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.selectAccountIn,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            ...state.accounts.map((acc) => ListTile(
                  leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blueAccent),
                  title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    state.confirmSettlement(tx.id, targetAccountId: acc.id);
                  },
                )),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: Text(state.accounts.isEmpty ? s.confirmWithoutAccount : s.noHistoryForAccount),
              onTap: () {
                Navigator.pop(ctx);
                state.confirmSettlement(tx.id);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }



  Widget _buildAvatarSection(Color accentColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: CategoryIcon(category: tx.category, size: 18)),
    );
  }

  Widget _buildContentSection(bool isEdited, bool isDark, AppState state) {
    final statusColor = tx.status == TransactionStatus.pending
        ? Colors.orangeAccent
        : (tx.status == TransactionStatus.rejected ? Colors.redAccent : Colors.green);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  tx.isPayment
                      ? (tx.status == TransactionStatus.pending
                          ? s.needsConfirmation
                          : (tx.participants.contains(state.me?.id)
                              ? '${s.receivingFrom} ${people.firstWhere((p) => p.id == tx.payerId, orElse: () => Person(name: '?')).name}'
                              : '${s.settlingTo} ${people.firstWhere((p) => p.id == (tx.participants.isNotEmpty ? tx.participants[0] : ''), orElse: () => Person(name: '?')).name}'))
                      : tx.description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tx.isPayment) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: statusColor),
                  ),
                ),
              ],
              if (isEdited) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded,
                          size: 8, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${s.edited} ${UIHelpers.formatSmartDate(tx.updatedAt!, s)}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 4),
          _ParticipantIcons(
              payerId: tx.payerId,
              creatorId: tx.creatorId,
              participants: tx.participants,
              people: people,
              s: s),
        ],
      ),
    );
  }

  Widget _buildAmountSection(Color accentColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          fmt.format(tx.amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${UIHelpers.formatSmartDate(tx.date, s)} • ${DateFormat('HH:mm').format(tx.date)}',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45),
        ),
      ],
    );
  }
}

class _ParticipantIcons extends StatelessWidget {
  final String payerId;
  final String? creatorId;
  final List<String> participants;
  final List<Person> people;
  final AppStrings s;

  const _ParticipantIcons({
    required this.payerId,
    this.creatorId,
    required this.participants,
    required this.people,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final creator = people.firstWhere((p) => p.id == (creatorId ?? payerId),
        orElse: () => Person(name: s.unknownMember));
    final payer = people.firstWhere((p) => p.id == payerId,
        orElse: () => Person(name: s.unknownMember));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text('${s.entryBy}: ${creator.name}',
              style: TextStyle(
                  fontSize: 7.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(payer.name,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.blueAccent.withValues(alpha: 0.8) : Colors.blue.withValues(alpha: 0.8))),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded,
                size: 9, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(width: 8),
            SizedBox(
              height: 16,
              width: participants.isEmpty ? 0 : (participants.length - 1) * 10.0 + 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(participants.length, (i) {
                  final p = people.firstWhere((p) => p.id == participants[i],
                      orElse: () => Person(name: '?'));
                  final avatarColor = UIHelpers.getAvatarColor(p.colorIndex);
                  return Positioned(
                    left: i * 10.0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                            width: 0.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.all(0.5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: avatarColor,
                          image: p.avatarUrl.isNotEmpty
                              ? (p.avatarUrl.startsWith('http')
                                  ? DecorationImage(
                                      image: NetworkImage(p.avatarUrl),
                                      fit: BoxFit.cover)
                                  : (File(p.avatarUrl).existsSync()
                                      ? DecorationImage(
                                          image: FileImage(File(p.avatarUrl)),
                                          fit: BoxFit.cover)
                                      : null))
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: p.avatarUrl.isEmpty ||
                                (!p.avatarUrl.startsWith('http') &&
                                    !File(p.avatarUrl).existsSync())
                            ? Text(
                                p.name.substring(0, 1).toLowerCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DateGroup extends StatelessWidget {
  final DateTime date;
  final List<GroupTransaction> transactions;
  final List<Person> people;
  final NumberFormat fmt;
  final AppStrings s;

  const DateGroup({
    super.key,
    required this.date,
    required this.transactions,
    required this.people,
    required this.fmt,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1;

    String dateLabel = isToday
        ? s.today
        : (isYesterday ? s.yesterday : DateFormat('dd MMMM yyyy').format(date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
          child: Text(
            dateLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...transactions.map(
            (tx) => TransactionCard(tx: tx, people: people, fmt: fmt, s: s)),
      ],
    );
  }
}
