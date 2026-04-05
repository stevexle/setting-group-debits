import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/navigation_state.dart';
import 'billshare/billshare_screen.dart';
import 'group_management_screen.dart';
import 'wallet/wallet_screen.dart';
import 'planning/planning_hub_screen.dart';
import 'ledger/ledger_screen.dart';
import '../l10n/strings.dart';

class MainTabHub extends StatefulWidget {
  const MainTabHub({super.key});

  @override
  State<MainTabHub> createState() => _MainTabHubState();
}

class _MainTabHubState extends State<MainTabHub> {
  final List<Widget> _screens = [
    const GroupManagementScreen(), // Tab 0: Groups Hub
    const BillShareScreen(), // Tab 1: BillShare Engine
    const WalletScreen(), // Tab 2: Assets (Home)
    const LedgerScreen(), // Tab 3: Thu Chi (Ledger)
    const PlanningHubScreen(), // Tab 4: Projects
  ];

  @override
  Widget build(BuildContext context) {
    final navState = context.watch<TabNavigationState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: navState.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(context, navState, isDark, cs),
    );
  }

  Widget _buildBottomNav(BuildContext context, TabNavigationState navState,
      bool isDark, ColorScheme cs) {
    final s = AppStrings.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: navState.currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          navState.setTab(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: cs.primary,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w900, fontSize: 8),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 8),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.group_work_rounded),
            label: s.navGroups,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: s.navBillShare,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: s.navWallet,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.swap_vert_rounded),
            label: s.navLedger,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome_motion_rounded),
            label: s.navPlanning,
          ),
        ],
      ),
    );
  }
}
