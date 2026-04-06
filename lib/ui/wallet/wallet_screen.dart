import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../widgets/common_widgets.dart';
import 'add_account_modal.dart';
import 'account_detail_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    final accounts = state.accounts;

    return MainScreenScaffold(
      title: s.walletTitle,
      fab: _buildAddAccountButton(context, s, isDark),
      children: [
        _buildTotalNetWorthCard(
            context, s, state.totalNetWorth, currencyFormat, isDark),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            s.accountsLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (accounts.isEmpty)
          EmptyCard(
            message: s.noAccountsMsg,
            icon: Icons.add_card_rounded,
          )
        else
          ...accounts.map((acc) => GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AccountDetailScreen(account: acc))),
                child: _buildAccountCard(context, acc, currencyFormat, isDark),
              )),
      ],
    );
  }

  Widget _buildTotalNetWorthCard(BuildContext context, AppStrings s,
      double totalValue, NumberFormat fmt, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return SummaryActionCard(
      title: s.totalNetWorthLabel,
      gradientColors: [
        cs.primary,
        cs.primary.withValues(alpha: 0.8),
      ],
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          fmt.format(totalValue),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTrendItem(Icons.account_balance_rounded, s.addAccount,
                fmt.format(totalValue), Colors.white.withValues(alpha: 0.9)),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAccountCard(
      BuildContext context, Account acc, NumberFormat fmt, bool isDark) {
    IconData icon;
    Color iconColor;
    switch (acc.type) {
      case AccountType.cash:
        icon = Icons.payments_rounded;
        iconColor = Colors.green;
        break;
      case AccountType.bank:
        icon = Icons.account_balance_rounded;
        iconColor = Colors.blue;
        break;
      case AccountType.creditCard:
        icon = Icons.credit_card_rounded;
        iconColor = Colors.purple;
        break;
      case AccountType.asset:
        icon = Icons.diamond_rounded;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.wallet_rounded;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(acc.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  Text(acc.type.name.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Text(fmt.format(acc.currentBalance),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAccountButton(
      BuildContext context, AppStrings s, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return DashboardFAB(
      enabled: true,
      label: s.addAccount,
      cs: cs,
      onTap: () => AddAccountModal.show(context),
    );
  }
}
