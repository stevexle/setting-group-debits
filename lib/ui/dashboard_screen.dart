import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
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

  static void showAddMember(BuildContext context, AppStrings s,
      {Person? existingPerson}) {
    final ctrl = TextEditingController(text: existingPerson?.name);
    final state = context.read<AppState>();
    int selectedColor = existingPerson?.colorIndex ??
        (DateTime.now().millisecondsSinceEpoch % 8);
    String currentAvatarPath = existingPerson?.avatarUrl ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => UIHelpers.showLiquidDialogWidget(
          context: ctx,
          title: existingPerson == null ? s.addMemberTitle : s.edit,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = image_picker.ImagePicker();
                  final image_picker.XFile? image =
                      await picker.pickImage(source: image_picker.ImageSource.gallery);
                  if (image != null) {
                    setState(() => currentAvatarPath = image.path);
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: UIHelpers.getAvatarColor(selectedColor)
                            .withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white24, width: 2),
                        image: currentAvatarPath.isNotEmpty
                            ? (currentAvatarPath.startsWith('http')
                                ? DecorationImage(
                                    image: NetworkImage(currentAvatarPath),
                                    fit: BoxFit.cover)
                                : (File(currentAvatarPath).existsSync()
                                    ? DecorationImage(
                                        image: FileImage(File(currentAvatarPath)),
                                        fit: BoxFit.cover)
                                    : null))
                            : null,
                      ),
                      child: currentAvatarPath.isEmpty ||
                              (!currentAvatarPath.startsWith('http') &&
                                  !File(currentAvatarPath).existsSync())
                          ? Icon(Icons.person_rounded,
                              size: 40,
                              color: UIHelpers.getAvatarColor(selectedColor))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(ctx).colorScheme.primary),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              StyledTextField(controller: ctrl, hint: s.enterName),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(8, (i) {
                  final color = UIHelpers.getAvatarColor(i);
                  final selected = selectedColor == i;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 2),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          confirmLabel: existingPerson == null ? s.add : s.save,
          onConfirm: () {
            if (ctrl.text.trim().isNotEmpty) {
              if (existingPerson == null) {
                state.addPerson(ctrl.text.trim(),
                    colorIndex: selectedColor, avatarUrl: currentAvatarPath);
              } else {
                state.updatePerson(existingPerson.id,
                    name: ctrl.text.trim(),
                    colorIndex: selectedColor,
                    avatarUrl: currentAvatarPath);
              }
            }
          },
        ),
      ),
    );
  }

  static void confirmRemovePerson(
      BuildContext context, Person person, AppStrings s) {
    final state = context.read<AppState>();
    final hasHistory = state.transactions.any(
        (t) => t.payerId == person.id || t.participantIds.contains(person.id));
    if (hasHistory) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Cannot remove member who has participated in expenses.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    UIHelpers.showLiquidDialog(
      context: context,
      title: '${s.deleteMember.replaceFirst('?', '')} ${person.name}?',
      content: Text(s.deleteMemberMsg,
          style: TextStyle(color: Colors.grey.shade500)),
      confirmLabel: s.delete,
      isDestructive: true,
      onConfirm: () => state.removePerson(person.id),
    );
  }

  static void showPersonSummary(BuildContext context, Person person,
      AppStrings s, AppState state, NumberFormat fmt) {
    final paid = state.getPersonSpent(person.id);
    final share = state.getPersonShare(person.id);
    final net = paid - share;
    final isPos = net >= 0;
    final avatarColor = UIHelpers.getAvatarColor(person.colorIndex);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor.withValues(alpha: 0.1),
                border: Border.all(
                    color: avatarColor.withValues(alpha: 0.1), width: 2),
                image: person.avatarUrl.isNotEmpty
                    ? (person.avatarUrl.startsWith('http')
                        ? DecorationImage(
                            image: NetworkImage(person.avatarUrl),
                            fit: BoxFit.cover)
                        : (File(person.avatarUrl).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(person.avatarUrl)),
                                fit: BoxFit.cover)
                            : null))
                    : null,
              ),
              child: person.avatarUrl.isEmpty ||
                      (!person.avatarUrl.startsWith('http') &&
                          !File(person.avatarUrl).existsSync())
                  ? Center(
                      child: Text(person.name[0].toUpperCase(),
                          style: TextStyle(
                              color: avatarColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w900)))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(person.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            SummaryRow(
                label: s.totalPaid,
                value: fmt.format(paid),
                color: Colors.green),
            const SizedBox(height: 12),
            SummaryRow(
                label: s.yourShare,
                value: fmt.format(share),
                color: Colors.orange),
            const Divider(height: 32),
            SummaryRow(
                label: 'Net balance',
                value: (isPos ? '+' : '') + fmt.format(net),
                color: isPos
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                isBold: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showAddMember(context, s, existingPerson: person);
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(s.edit),
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: avatarColor.withValues(alpha: 0.5)),
                    foregroundColor: avatarColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0; // 0: Expenses, 1: Payments

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    final filteredTxs = state.transactions.where((t) {
      final isActuallyPayment =
          t.isPayment || t.description.startsWith('Settle:');
      return _selectedTab == 0 ? !isActuallyPayment : isActuallyPayment;
    }).toList();
    final groupedTx = _groupByDate(filteredTxs, s);

    if (state.isLoading) {
      return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
          body: LoadingSkeleton(isDark: isDark, cs: cs));
    }

    return Scaffold(
      floatingActionButton: state.people.isEmpty
          ? null
          : DashboardFAB(
              enabled: state.people.isNotEmpty,
              cs: cs,
              isDark: isDark,
              onTap: () => _openAddTransaction(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          _buildAmbientGlows(isDark, cs),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, state, s, isDark, cs, currencyFormat),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark, s),
                      _buildMembersSection(context, state, s, isDark, cs, currencyFormat),
                      const SizedBox(height: 28),
                      if (state.people.isNotEmpty && state.settlements.isNotEmpty) ...[
                        SettleUpCard(
                            state: state,
                            cs: cs,
                            isDark: isDark,
                            s: s,
                            fmt: currencyFormat,
                            onSettleTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SettlementScreen()))
                                .then((_) => setState(() => _selectedTab = 1))),
                        const SizedBox(height: 28),
                      ],
                      _buildTabSwitcher(s, isDark, cs),
                      if (state.settlements.isEmpty &&
                          state.transactions.any((t) => !t.isPayment) &&
                          _selectedTab == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: PrimaryChipButton(
                              label: s.deleteAll,
                              icon: Icons.auto_delete_rounded,
                              color: const Color(0xFFFF6B9D),
                              onTap: () => state.clearExpenses()),
                        ),
                      const SizedBox(height: 10),
                      _buildTransactionList(filteredTxs, groupedTx, state, s, isDark, cs, currencyFormat),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlows(bool isDark, ColorScheme cs) {
    if (isDark) {
      return Stack(children: [
        _ambientGlow(top: -150, left: -100, color: const Color(0xFF7B61FF), opacity: 0.15, size: 450),
        _ambientGlow(bottom: 50, right: -120, color: const Color(0xFF00D4FF), opacity: 0.1, size: 350),
      ]);
    }
    return Stack(children: [
      _ambientGlow(top: -100, right: -100, color: cs.primary, opacity: 0.15, size: 400),
      _ambientGlow(bottom: 100, left: -100, color: Colors.purpleAccent, opacity: 0.1, size: 350),
    ]);
  }

  Widget _buildAppBar(BuildContext context, AppState state, AppStrings s, bool isDark, ColorScheme cs, NumberFormat fmt) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.22,
      pinned: true,
      stretch: true,
      backgroundColor: isDark
          ? const Color(0xFF0E0E1A).withValues(alpha: 0.85)
          : const Color(0xFFF5F5FF).withValues(alpha: 0.9),
      title: GestureDetector(
        onTap: () => _showGroupSwitcher(context, state, s),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
                child: Text(state.groupName,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        fontFamily: 'Outfit'),
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.1)),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: cs.primary)),
          ],
        ),
      ),
      actions: [
        if (state.people.isNotEmpty || state.transactions.isNotEmpty)
          ActionIconButton(
              icon: Icons.delete_sweep_outlined,
              onTap: () => _confirmClearAll(context, s),
              isDark: isDark),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1A1535), const Color(0xFF0E0E1A)]
                            : [const Color(0xFFE8E8FF), const Color(0xFFF5F5FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter))),
            Positioned(
                bottom: 10,
                left: 16,
                right: 16,
                child: DashboardStatsCard(
                    state: state, cs: cs, isDark: isDark, s: s, fmt: fmt)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(s.appTitle,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                fontFamily: 'Outfit')),
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, AppState state, AppStrings s, bool isDark, ColorScheme cs, NumberFormat fmt) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SectionLabel(title: s.members, icon: Icons.people_alt_rounded, cs: cs, isDark: isDark),
          ActionIconButton(icon: Icons.add_rounded, onTap: () => DashboardScreen.showAddMember(context, s), isDark: isDark),
        ],
      ),
      const SizedBox(height: 10),
      MembersRow(
          state: state,
          s: s,
          cs: cs,
          isDark: isDark,
          fmt: fmt,
          showAddMember: DashboardScreen.showAddMember,
          showPersonSummary: DashboardScreen.showPersonSummary,
          confirmRemovePerson: DashboardScreen.confirmRemovePerson),
    ]);
  }

  Widget _buildTabSwitcher(AppStrings s, bool isDark, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
            child: SectionLabel(
                title: _selectedTab == 0 ? s.tabPay : s.tabBill,
                icon: _selectedTab == 0 ? Icons.receipt_rounded : Icons.payments_rounded,
                cs: cs,
                isDark: isDark)),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HistoryTab(
                  label: s.tabPay,
                  active: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                  isDark: isDark,
                  cs: cs),
              HistoryTab(
                  label: s.tabBill,
                  active: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                  isDark: isDark,
                  cs: cs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<Transaction> filteredTxs, Map<String, List<Transaction>> groupedTx, AppState state, AppStrings s, bool isDark, ColorScheme cs, NumberFormat fmt) {
    if (filteredTxs.isEmpty) {
      return EmptyCard(
          icon: _selectedTab == 0 ? Icons.coffee_rounded : Icons.payments_rounded,
          title: _selectedTab == 0 ? s.noExpenses : s.tabPay,
          subtitle: _selectedTab == 0 ? s.noExpensesSubtitle : '',
          cs: cs,
          isDark: isDark);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.longPressHint,
          style: TextStyle(
              fontSize: 10, color: isDark ? Colors.white24 : Colors.black26)),
      const SizedBox(height: 8),
      Column(
          children: groupedTx.entries
              .map((e) => DateGroup(
                  dateLabel: e.key,
                  txs: e.value,
                  state: state,
                  cs: cs,
                  isDark: isDark,
                  fmt: fmt,
                  s: s))
              .toList()),
    ]);
  }

  void _openAddTransaction(BuildContext context) {
    HapticFeedback.lightImpact();
    setState(() => _selectedTab = 0);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTransactionModal());
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txs, AppStrings s) {
    final sorted = [...txs]..sort((a, b) => b.date.compareTo(a.date));
    final map = <String, List<Transaction>>{};
    final now = DateTime.now();
    for (final tx in sorted) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(tx.date.year, tx.date.month, tx.date.day))
          .inDays;
      String label = diff == 0
          ? s.today
          : (diff == 1
              ? s.yesterday
              : DateFormat('EEEE, dd/MM/yyyy').format(tx.date));
      map.putIfAbsent(label, () => []).add(tx);
    }
    return map;
  }

  void _confirmClearAll(BuildContext context, AppStrings s) {
    UIHelpers.showLiquidDialog(
        context: context,
        title: 'New Group / Reset',
        content: Text(s.confirmDeleteMsg,
            style: TextStyle(color: Colors.grey.shade500)),
        confirmLabel: 'Reset All',
        isDestructive: true,
        onConfirm: () => context.read<AppState>().clearAll());
  }

  void _showGroupSwitcher(BuildContext context, AppState state, AppStrings s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? const Color(0xFF0E0E1A).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
                color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.1),
                width: 1.5)),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.myGroups,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit')),
                Row(
                  children: [
                    PrimaryChipButton(
                        label: s.addGroup,
                        icon: Icons.add_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _showCreateGroup(context, state);
                        }),
                    const SizedBox(width: 8),
                    ActionIconButton(
                        icon: Icons.settings_rounded,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const GroupManagementScreen()));
                        },
                        isDark: isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Consumer<AppState>(
              builder: (ctx, state, child) => ListView.builder(
                shrinkWrap: true,
                itemCount: state.groups.length,
                itemBuilder: (ctx, i) {
                  final g = state.groups[i];
                  final isSelected = g.id == state.activeGroupId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected
                            ? Theme.of(ctx)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                            color: isSelected
                                ? Theme.of(ctx)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.1))),
                    child: ListTile(
                      title: Text(g.name,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Theme.of(ctx).colorScheme.primary
                                  : null)),
                      subtitle: Text(
                          '${g.people.length} ${s.people} • ${g.transactions.length} txs',
                          style: const TextStyle(fontSize: 12)),
                      trailing: isSelected
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 20),
                                    onPressed: () =>
                                        _showEditGroupName(context, state, s)),
                                if (state.groups.length > 1)
                                  IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20),
                                      onPressed: () {
                                        if (state.isGroupBalanced(g.id)) {
                                          state.deleteGroup(g.id);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Cannot delete group with unresolved balances.'),
                                                  behavior: SnackBarBehavior
                                                      .floating));
                                        }
                                      }),
                              ],
                            )
                          : null,
                      onTap: () {
                        state.switchGroup(g.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroup(BuildContext context, AppState state) {
    final s = AppStrings.of(context);
    final ctrl = TextEditingController();
    UIHelpers.showLiquidDialog(
        context: context,
        title: s.newGroupName,
        content: StyledTextField(controller: ctrl, hint: 'e.g. Vacation 2024'),
        confirmLabel: AppStrings.of(context).add,
        onConfirm: () => state.createGroup(ctrl.text.trim()));
  }

  void _showEditGroupName(BuildContext context, AppState state, AppStrings s) {
    final ctrl = TextEditingController(text: state.groupName);
    UIHelpers.showLiquidDialog(
        context: context,
        title: s.editName,
        content: StyledTextField(controller: ctrl, hint: s.enterName),
        confirmLabel: s.save,
        onConfirm: () =>
            state.setGroupName(state.activeGroupId!, ctrl.text.trim()));
  }

  Widget _ambientGlow(
      {double? top, double? bottom, double? left, double? right, required Color color, required double opacity, required double size}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.1),
          duration: const Duration(seconds: 5),
          builder: (context, scale, _) => Container(
            width: size * scale,
            height: size * scale,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color.withValues(alpha: opacity),
                  Colors.transparent
                ])),
          ),
        ),
      ),
    );
  }
}

class DashboardFAB extends StatelessWidget {
  final bool enabled;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onTap;
  const DashboardFAB(
      {required this.enabled,
      required this.cs,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled
                  ? LinearGradient(
                      colors: [cs.primary, cs.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)
                  : LinearGradient(colors: [
                      isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.08),
                      isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.04)
                    ]),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                          color: cs.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ]
                  : []),
          child: Icon(Icons.add_rounded,
              color: enabled
                  ? Colors.white
                  : (isDark ? Colors.white24 : Colors.black26),
              size: 28)));
}
