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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161625) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          CategoryIcon(category: tx.category, size: 48),
          const SizedBox(height: 16),
          Text(
            tx.description.toUpperCase(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '${tx.isPayment ? "+" : "-"}${fmt.format(tx.amount)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: tx.isPayment ? Colors.green : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.calendar_today_rounded, s.dateTime, UIHelpers.formatSmartDate(tx.date, s), isDark),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.category_rounded, s.category, s.getCategoryName(tx.category), isDark),
          const SizedBox(height: 12),
          if (tx is PersonalTransaction) ...[
             _buildInfoRow(Icons.account_balance_wallet_rounded, s.navWallet, (tx as PersonalTransaction).sourceAccountId ?? "N/A", isDark),
          ],
          if (tx is GroupTransaction) ...[
             _buildInfoRow(Icons.person_rounded, s.paidBy, (tx as GroupTransaction).payerId, isDark),
             _buildInfoRow(Icons.group_rounded, s.members, "${(tx as GroupTransaction).participants.length} ${s.people}", isDark),
             
             if (tx.isPayment) ...[
                const SizedBox(height: 16),
                _buildLinkToWalletSection(context, state, tx as GroupTransaction, s, isDark),
             ]
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(s.done, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        gradientColors: [
          Colors.green.withValues(alpha: 0.1),
          Colors.green.withValues(alpha: 0.05)
        ],
        opacity: 0.1,
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text("${s.recordedTo}$accName", style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
