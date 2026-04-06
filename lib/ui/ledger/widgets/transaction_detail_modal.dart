import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../../state/app_state.dart';
import '../../widgets/base/glass_container.dart';
import '../../widgets/elements/category_icon.dart';
import '../../ui_helpers.dart';

class TransactionDetailModal extends StatelessWidget {
  final BaseTransaction tx;

  const TransactionDetailModal({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final state = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161625) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          CategoryIcon(category: tx.category, size: 56),
          const SizedBox(height: 16),
          Text(
            tx.description.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '${tx.isPayment ? "+" : "-"}${fmt.format(tx.amount)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: tx.isPayment
                  ? Colors.green
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          if (tx is GroupTransaction)
            _buildStatusBadge((tx as GroupTransaction).status, s),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildCompactInfo(Icons.calendar_today_rounded, s.dateTime,
                  UIHelpers.formatSmartDate(tx.date, s), isDark),
              _buildCompactInfo(Icons.category_rounded, s.category,
                  s.getCategoryName(tx.category), isDark),
              if (tx is PersonalTransaction)
                _buildCompactInfo(
                    Icons.account_balance_wallet_rounded,
                    s.navWallet,
                    state.accounts
                        .firstWhere((a) => a.id == (tx as PersonalTransaction).sourceAccountId,
                            orElse: () => Account(
                                id: '', name: 'N/A', icon: '', currentBalance: 0))
                        .name,
                    isDark),
              if (tx is GroupTransaction) ...[
                _buildCompactInfo(
                    Icons.person_rounded,
                    s.paidBy,
                    state.people
                        .firstWhere((p) => p.id == (tx as GroupTransaction).payerId,
                            orElse: () => Person(name: '?'))
                        .name,
                    isDark),
                _buildCompactInfo(
                    Icons.create_rounded,
                    "Người tạo",
                    state.people
                        .firstWhere((p) => p.id == (tx as GroupTransaction).creatorId,
                            orElse: () => Person(name: 'Hệ thống'))
                        .name,
                    isDark),
              ],
            ],
          ),
          if (tx is GroupTransaction) ...[
            const SizedBox(height: 24),
            _buildParticipantsSection(state, tx as GroupTransaction, s, isDark),
            if (tx.isPayment) ...[
              const SizedBox(height: 24),
              _buildLinkToWalletSection(context, state, tx as GroupTransaction, s, isDark),
            ]
          ],
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black87,
              foregroundColor: isDark ? Colors.black87 : Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
            ),
            child: Text(s.done, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status, AppStrings s) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case TransactionStatus.confirmed:
        color = Colors.green;
        label = "Đã xác nhận";
        icon = Icons.check_circle_rounded;
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        label = "Chờ xác nhận";
        icon = Icons.hourglass_empty_rounded;
        break;
      case TransactionStatus.rejected:
        color = Colors.red;
        label = "Đã từ chối";
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(AppState state, GroupTransaction tx, AppStrings s, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 8),
              Text(
                "${s.whoSplits.toUpperCase()} (${tx.participants.length})",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tx.participants.map((pid) {
              final person = state.people.firstWhere((p) => p.id == pid, orElse: () => Person(name: '?'));
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  person.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String label, String value, bool isDark) {
    return SizedBox(
      width: 150,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkToWalletSection(BuildContext context, AppState state, GroupTransaction gtx, AppStrings s, bool isDark) {
    final myUid = state.me?.id;
    if (myUid == null) return const SizedBox.shrink();
    
    final isParticipant = gtx.participants.contains(myUid);
    final isLinked = gtx.participantBalances?.containsKey(myUid) ?? false;
    
    if (isParticipant && !isLinked) {
      return OutlinedButton.icon(
        onPressed: () {
          UIHelpers.showAccountPicker(
            context: context,
            state: state,
            onSelected: (acc) {
              state.linkGroupTransactionToWallet(gtx.id, acc.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã hạch toán vào ví!")),
              );
            },
          );
        },
        icon: const Icon(Icons.link_rounded),
        label: Text(s.recordToWallet),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } else if (isLinked) {
      final accId = gtx.participantBalances![myUid]!;
      final accName = state.accounts.firstWhere((a) => a.id == accId, orElse: () => state.accounts.first).name;
      return GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        opacity: 0.1,
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text("${s.recordedTo}$accName", 
                style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}
