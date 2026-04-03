import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../models.dart';
import '../../../state/app_state.dart';
import '../../../l10n/strings.dart';
import '../../ui_helpers.dart';
import '../../add_transaction_modal.dart';
import 'common_widgets.dart';

void confirmRemoveTransaction(
    BuildContext context, Transaction tx, AppStrings s) {
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
                  fontFamily: 'Outfit',
                  fontSize: 14),
              children: [
                const TextSpan(text: 'Delete '),
                TextSpan(
                    text: ' ${tx.description} ',
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
    onConfirm: () => state.removeTransaction(tx.id),
  );
}

class TransactionCard extends StatelessWidget {
  final Transaction tx;
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
    final isEdited = tx.updatedAt != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onLongPress: tx.isPayment ? null : () => _showActions(context),
              onTap: tx.isPayment ? null : () => _showActions(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildAvatarSection(accentColor),
                    const SizedBox(width: 16),
                    _buildContentSection(isEdited, isDark),
                    const SizedBox(width: 12),
                    _buildAmountSection(accentColor, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    HapticFeedback.lightImpact();
    final state = context.read<AppState>();
    final isLocked = state.hasSettlements && !tx.isPayment;

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
            if (isLocked)
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
            Opacity(
              opacity: isLocked ? 0.3 : 1.0,
              child: ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(s.edit),
                onTap: isLocked
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddTransactionModal(initialTransaction: tx),
                        );
                      },
              ),
            ),
            Opacity(
              opacity: isLocked ? 0.3 : 1.0,
              child: ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: Text(s.delete, style: const TextStyle(color: Colors.red)),
                onTap: isLocked
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        confirmRemoveTransaction(context, tx, s);
                      },
              ),
            ),
            const SizedBox(height: 12),
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

  Widget _buildContentSection(bool isEdited, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  tx.description,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontFamily: 'Outfit'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isEdited) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded, size: 8, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${s.edited} ${UIHelpers.formatSmartDate(tx.updatedAt!, s)}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          fontFamily: 'Outfit',
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
              participantIds: tx.participantIds,
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
              fontFamily: 'Outfit'),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('HH:mm').format(tx.date),
          style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white30 : Colors.black26),
        ),
      ],
    );
  }
}

class _ParticipantIcons extends StatelessWidget {
  final String payerId;
  final List<String> participantIds;
  final List<Person> people;
  final AppStrings s;

  const _ParticipantIcons({
    required this.payerId,
    required this.participantIds,
    required this.people,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final payer = people.firstWhere((p) => p.id == payerId,
        orElse: () => Person(name: 'Unknown'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleIds = participantIds.where((id) => id != payerId).toList();

    return Row(
      children: [
        Text(payer.name,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white54 : Colors.black45)),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward_rounded,
            size: 10, color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(width: 6),
        SizedBox(
          height: 16,
          width: visibleIds.isEmpty ? 0 : (visibleIds.length - 1) * 10.0 + 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(visibleIds.length, (i) {
              final p = people.firstWhere((p) => p.id == visibleIds[i],
                  orElse: () => Person(name: '?'));
              final avatarColor = UIHelpers.getAvatarColor(p.colorIndex);
              return Positioned(
                left: i * 10.0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5),
                    color: avatarColor.withValues(alpha: 0.2),
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
                  child: p.avatarUrl.isEmpty ||
                          (!p.avatarUrl.startsWith('http') &&
                              !File(p.avatarUrl).existsSync())
                      ? Center(
                          child: Text(p.name[0].toUpperCase(),
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: avatarColor)))
                      : null,
                ),
              );
            }),
          ),
        ),
        if (visibleIds.isEmpty)
          Text(s.splitEqual,
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white24 : Colors.black26)),
      ],
    );
  }
}

class DateGroup extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
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
              color: isDark ? Colors.white30 : Colors.black26,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...transactions
            .map((tx) => TransactionCard(tx: tx, people: people, fmt: fmt, s: s))
            .toList(),
      ],
    );
  }
}
