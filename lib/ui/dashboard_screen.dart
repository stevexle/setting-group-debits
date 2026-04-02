import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../l10n/strings.dart';
import 'ui_helpers.dart';
import 'add_transaction_modal.dart';
import 'settlement_screen.dart';
import 'group_management_screen.dart';

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
                  final picker = ImagePicker();
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
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
                        image: currentAvatarPath.isNotEmpty &&
                                File(currentAvatarPath).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(currentAvatarPath)),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: currentAvatarPath.isEmpty ||
                              !File(currentAvatarPath).existsSync()
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
              _StyledTextField(controller: ctrl, hint: s.enterName),
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
                image: person.avatarUrl.isNotEmpty &&
                        File(person.avatarUrl).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(person.avatarUrl)),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: person.avatarUrl.isEmpty ||
                      !File(person.avatarUrl).existsSync()
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
            _SummaryRow(
                label: s.totalPaid,
                value: fmt.format(paid),
                color: Colors.green),
            const SizedBox(height: 12),
            _SummaryRow(
                label: s.yourShare,
                value: fmt.format(share),
                color: Colors.orange),
            const Divider(height: 32),
            _SummaryRow(
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
          body: _LoadingSkeleton(isDark: isDark, cs: cs));
    }

    return Scaffold(
      floatingActionButton: state.people.isEmpty
          ? null
          : _FAB(
              enabled: state.people.isNotEmpty,
              cs: cs,
              isDark: isDark,
              onTap: () => _openAddTransaction(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          if (isDark) ...[
            _ambientGlow(
                top: -150,
                left: -100,
                color: const Color(0xFF7B61FF),
                opacity: 0.15,
                size: 450),
            _ambientGlow(
                bottom: 50,
                right: -120,
                color: const Color(0xFF00D4FF),
                opacity: 0.1,
                size: 350),
          ] else ...[
            _ambientGlow(
                top: -100,
                right: -100,
                color: cs.primary,
                opacity: 0.15,
                size: 400),
            _ambientGlow(
                bottom: 100,
                left: -100,
                color: Colors.purpleAccent,
                opacity: 0.1,
                size: 350),
          ],
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
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
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
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
                    _ActionIconButton(
                        icon: Icons.delete_sweep_outlined,
                        onTap: () => _confirmClearAll(context, s),
                        isDark: isDark),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF1A1535),
                                          const Color(0xFF0E0E1A)
                                        ]
                                      : [
                                          const Color(0xFFE8E8FF),
                                          const Color(0xFFF5F5FF)
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter))),
                      Positioned(
                          bottom: 10,
                          left: 16,
                          right: 16,
                          child: _StatsCard(
                              state: state,
                              cs: cs,
                              isDark: isDark,
                              s: s,
                              fmt: currencyFormat)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(s.appTitle,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1A1A2E),
                                      fontFamily: 'Outfit')))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionLabel(
                              title: s.members,
                              icon: Icons.people_alt_rounded,
                              cs: cs,
                              isDark: isDark),
                          _ActionIconButton(
                              icon: Icons.add_rounded,
                              onTap: () =>
                                  DashboardScreen.showAddMember(context, s),
                              isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MembersRow(
                          state: state,
                          s: s,
                          cs: cs,
                          isDark: isDark,
                          fmt: currencyFormat),
                      const SizedBox(height: 28),
                      if (state.people.isNotEmpty &&
                          state.settlements.isNotEmpty) ...[
                        _SettleUpCard(
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
                      Row(
                        children: [
                          Expanded(
                              child: _SectionLabel(
                                  title:
                                      _selectedTab == 0 ? s.tabPay : s.tabBill,
                                  icon: _selectedTab == 0
                                      ? Icons.receipt_rounded
                                      : Icons.payments_rounded,
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
                                _HistoryTab(
                                    label: s.tabPay,
                                    active: _selectedTab == 0,
                                    onTap: () =>
                                        setState(() => _selectedTab = 0),
                                    isDark: isDark,
                                    cs: cs),
                                _HistoryTab(
                                    label: s.tabBill,
                                    active: _selectedTab == 1,
                                    onTap: () =>
                                        setState(() => _selectedTab = 1),
                                    isDark: isDark,
                                    cs: cs),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (state.settlements.isEmpty &&
                          state.transactions.any((t) => !t.isPayment) &&
                          _selectedTab == 0)
                        _PrimaryChipButton(
                            label: s.deleteAll,
                            icon: Icons.auto_delete_rounded,
                            color: const Color(0xFFFF6B9D),
                            onTap: () => state.clearExpenses()),
                      const SizedBox(height: 10),
                      if (filteredTxs.isEmpty)
                        _EmptyCard(
                            icon: _selectedTab == 0
                                ? Icons.coffee_rounded
                                : Icons.payments_rounded,
                            title: _selectedTab == 0 ? s.noExpenses : s.tabPay,
                            subtitle:
                                _selectedTab == 0 ? s.noExpensesSubtitle : '',
                            cs: cs,
                            isDark: isDark)
                      else ...[
                        Text(s.longPressHint,
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    isDark ? Colors.white24 : Colors.black26)),
                        const SizedBox(height: 8),
                        Column(
                            children: groupedTx.entries
                                .map((e) => _DateGroup(
                                    dateLabel: e.key,
                                    txs: e.value,
                                    state: state,
                                    cs: cs,
                                    isDark: isDark,
                                    fmt: currencyFormat,
                                    s: s))
                                .toList()),
                      ]
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

  void _openAddTransaction(BuildContext context) {
    HapticFeedback.lightImpact();
    setState(() => _selectedTab = 0);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTransactionModal());
  }

  Map<String, List<Transaction>> _groupByDate(
      List<Transaction> txs, AppStrings s) {
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
                    _PrimaryChipButton(
                        label: s.addGroup,
                        icon: Icons.add_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _showCreateGroup(context, state);
                        }),
                    const SizedBox(width: 8),
                    _ActionIconButton(
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
        content: _StyledTextField(controller: ctrl, hint: 'e.g. Vacation 2024'),
        confirmLabel: AppStrings.of(context).add,
        onConfirm: () => state.createGroup(ctrl.text.trim()));
  }

  void _showEditGroupName(BuildContext context, AppState state, AppStrings s) {
    final ctrl = TextEditingController(text: state.groupName);
    UIHelpers.showLiquidDialog(
        context: context,
        title: s.editName,
        content: _StyledTextField(controller: ctrl, hint: s.enterName),
        confirmLabel: s.save,
        onConfirm: () =>
            state.setGroupName(state.activeGroupId!, ctrl.text.trim()));
  }

  Widget _ambientGlow(
      {double? top,
      double? bottom,
      double? left,
      double? right,
      required Color color,
      required double opacity,
      required double size}) {
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

class _StatsCard extends StatelessWidget {
  final AppState state;
  final ColorScheme cs;
  final bool isDark;
  final AppStrings s;
  final NumberFormat fmt;
  const _StatsCard(
      {required this.state,
      required this.cs,
      required this.isDark,
      required this.s,
      required this.fmt});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.8),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : cs.primary.withValues(alpha: 0.15))),
            child: Row(
              children: [
                _StatItem(
                    label: s.totalMembers,
                    value: '${state.people.length}',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF00D4FF)),
                _vDivider(isDark),
                _StatItem(
                    label: s.thisWeek,
                    value: _short(state.weeklyTotal),
                    icon: Icons.insights_rounded,
                    color: const Color(0xFF7B61FF)),
                _vDivider(isDark),
                _StatItem(
                    label: s.thisMonth,
                    value: _short(state.monthlyTotal),
                    icon: Icons.auto_graph_rounded,
                    color: const Color(0xFFFF6B9D)),
              ],
            ),
          ),
        ),
      );
  Widget _vDivider(bool isDark) => Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isDark ? Colors.white12 : Colors.black12);
  String _short(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : (v >= 1000
          ? '${(v / 1000).toStringAsFixed(0)}K'
          : v.toStringAsFixed(0));
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
            child: Icon(icon, size: 16, color: color)),
        const SizedBox(height: 6),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    fontFamily: 'Outfit',
                    letterSpacing: -0.5))),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2),
            maxLines: 1),
      ]),
    );
  }
}

class _MembersRow extends StatelessWidget {
  final AppState state;
  final AppStrings s;
  final ColorScheme cs;
  final bool isDark;
  final NumberFormat fmt;
  const _MembersRow(
      {required this.state,
      required this.s,
      required this.cs,
      required this.isDark,
      required this.fmt});
  @override
  Widget build(BuildContext context) {
    if (state.people.isEmpty)
      return _EmptyCard(
          icon: Icons.group_add_rounded,
          title: s.noMembers,
          subtitle: s.noMembersSubtitle,
          cs: cs,
          isDark: isDark,
          onTap: () => DashboardScreen.showAddMember(context, s));
    return SizedBox(
        height: 112,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: state.people.length + 1,
            itemBuilder: (context, i) => i == state.people.length
                ? _AddMemberCell(
                    onTap: () => DashboardScreen.showAddMember(context, s),
                    cs: cs,
                    isDark: isDark,
                    label: s.addMember)
                : _MemberCell(
                    person: state.people[i],
                    net: state.getPersonNetBalance(state.people[i].id),
                    isDark: isDark,
                    cs: cs,
                    s: s)));
  }
}

class _AddMemberCell extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isDark;
  final String label;
  const _AddMemberCell(
      {required this.onTap,
      required this.cs,
      required this.isDark,
      required this.label});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.4),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.15)),
                child: Icon(Icons.add_rounded, color: cs.primary, size: 24)),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Outfit'))
          ])));
}

class _MemberCell extends StatelessWidget {
  final Person person;
  final double net;
  final bool isDark;
  final ColorScheme cs;
  final AppStrings s;
  const _MemberCell(
      {required this.person,
      required this.net,
      required this.isDark,
      required this.cs,
      required this.s});
  @override
  Widget build(BuildContext context) {
    final avatarColor = UIHelpers.getAvatarColor(person.colorIndex);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return GestureDetector(
      onTap: () => DashboardScreen.showPersonSummary(
          context, person, s, context.read<AppState>(), fmt),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        DashboardScreen.confirmRemovePerson(context, person, s);
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: [
              isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
              isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF0F0FF)
            ]),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: person.avatarUrl.isEmpty ||
                          !File(person.avatarUrl).existsSync()
                      ? LinearGradient(colors: [
                          avatarColor,
                          avatarColor.withValues(alpha: 0.7)
                        ])
                      : null,
                  image: person.avatarUrl.isNotEmpty &&
                          File(person.avatarUrl).existsSync()
                      ? DecorationImage(
                          image: FileImage(File(person.avatarUrl)),
                          fit: BoxFit.cover)
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: avatarColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]),
              child: person.avatarUrl.isEmpty ||
                      !File(person.avatarUrl).existsSync()
                  ? Center(
                      child: Text(person.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)))
                  : null),
          const SizedBox(height: 8),
          Text(person.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  fontFamily: 'Outfit')),
          const SizedBox(height: 4),
          _StatusChip(net: net, cs: cs)
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final double net;
  final ColorScheme cs;
  const _StatusChip({required this.net, required this.cs});
  @override
  Widget build(BuildContext context) {
    final pos = net >= 0;
    final color = pos ? const Color(0xFF00D4FF) : const Color(0xFFFF6B9D);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.1)),
        child: Text(net == 0 ? '±0' : (pos ? '+${_short(net)}' : _short(net)),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'Outfit')));
  }

  String _short(double v) {
    final abs = v.abs();
    return abs >= 1000000
        ? '${(abs / 1000000).toStringAsFixed(1)}M'
        : (abs >= 1000
            ? '${(abs / 1000).toStringAsFixed(0)}K'
            : abs.toStringAsFixed(0));
  }
}

class _DateGroup extends StatelessWidget {
  final String dateLabel;
  final List<Transaction> txs;
  final AppState state;
  final ColorScheme cs;
  final bool isDark;
  final NumberFormat fmt;
  final AppStrings s;
  const _DateGroup(
      {required this.dateLabel,
      required this.txs,
      required this.state,
      required this.cs,
      required this.isDark,
      required this.fmt,
      required this.s});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 12),
            child: Row(children: [
              Text(dateLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: Divider(
                      color: isDark ? Colors.white12 : Colors.black12,
                      thickness: 0.5)),
              const SizedBox(width: 10),
              Text(fmt.format(txs.fold(0.0, (a, b) => a + b.amount)),
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w600))
            ])),
        ...txs.map((tx) => _TxCard(
            tx: tx,
            payer: state.people.firstWhere((p) => p.id == tx.payerId,
                orElse: () => Person(name: '?')),
            fmt: fmt,
            cs: cs,
            isDark: isDark,
            s: s,
            state: state))
      ]);
}

class _TxCard extends StatelessWidget {
  final Transaction tx;
  final Person payer;
  final NumberFormat fmt;
  final ColorScheme cs;
  final bool isDark;
  final AppStrings s;
  final AppState state;
  const _TxCard(
      {required this.tx,
      required this.payer,
      required this.fmt,
      required this.cs,
      required this.isDark,
      required this.s,
      required this.state});
  @override
  Widget build(BuildContext context) {
    final color =
        tx.isPayment ? Colors.blue : UIHelpers.getAvatarColor(payer.colorIndex);
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
            onLongPress: tx.isPayment ? null : () => _showActions(context),
            onTap: tx.isPayment ? null : () => _showActions(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: [
                      isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      isDark
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.white.withValues(alpha: 0.8)
                    ]),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03))),
                child: Row(children: [
                  Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.1),
                          image: !tx.isPayment &&
                                  payer.avatarUrl.isNotEmpty &&
                                  File(payer.avatarUrl).existsSync()
                              ? DecorationImage(
                                  image: FileImage(File(payer.avatarUrl)),
                                  fit: BoxFit.cover)
                              : null),
                      child: tx.isPayment ||
                              payer.avatarUrl.isEmpty ||
                              !File(payer.avatarUrl).existsSync()
                          ? Center(
                              child: Text(
                                  tx.isPayment
                                      ? 'S'
                                      : payer.name[0].toUpperCase(),
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)))
                          : null),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(
                          children: [
                            Flexible(
                                child: Text(tx.description,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87))),
                            if (tx.customAmounts != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: cs.primary.withValues(alpha: 0.1),
                                    border: Border.all(
                                        color:
                                            cs.primary.withValues(alpha: 0.2))),
                                child: Text(s.splitCustom.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w900,
                                        color: cs.primary)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '${DateFormat('HH:mm').format(tx.date)} • ${tx.isPayment ? s.tabBill : '${s.paidBy} ${payer.name} • ${tx.participantIds.length} ${s.people}'}',
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    isDark ? Colors.white38 : Colors.black38))
                      ])),
                  Text(fmt.format(tx.amount),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color))
                ]))));
  }

  void _showActions(BuildContext context) => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
          decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0E0E1A).withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : cs.primary.withValues(alpha: 0.1),
                  width: 1.5)),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                leading: Icon(Icons.edit_rounded,
                    color: (!tx.isPayment && state.hasSettlements)
                        ? Colors.grey
                        : Colors.blue),
                title: Text(s.edit,
                    style: TextStyle(
                        color: (!tx.isPayment && state.hasSettlements)
                            ? Colors.grey
                            : null)),
                onTap: () {
                  Navigator.pop(_);
                  if (!tx.isPayment && state.hasSettlements) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(s.lockHistory),
                        behavior: SnackBarBehavior.floating));
                  } else {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            AddTransactionModal(initialTransaction: tx));
                  }
                }),
            ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: (!tx.isPayment && state.hasSettlements)
                        ? Colors.grey
                        : Colors.red),
                title: Text(s.delete,
                    style: TextStyle(
                        color: (!tx.isPayment && state.hasSettlements)
                            ? Colors.grey
                            : null)),
                onTap: () {
                  Navigator.pop(_);
                  if (!tx.isPayment && state.hasSettlements) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(s.lockHistory),
                        behavior: SnackBarBehavior.floating));
                  } else {
                    _confirmDelete(context);
                  }
                })
          ])));
  void _confirmDelete(BuildContext context) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
              title: Text(s.deleteExpense),
              content: Text(s.deleteExpenseMsg),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(_), child: Text(s.cancel)),
                TextButton(
                    onPressed: () {
                      state.removeTransaction(tx.id);
                      Navigator.pop(_);
                    },
                    child: Text(s.delete,
                        style: const TextStyle(color: Colors.red)))
              ]));
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme cs;
  final bool isDark;
  const _SectionLabel(
      {required this.title,
      required this.icon,
      required this.cs,
      required this.isDark});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary,
                boxShadow: [
                  BoxShadow(
                      color: cs.primary.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1)
                ])),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: cs.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                fontFamily: 'Outfit',
                letterSpacing: 0.2))
      ]);
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _ActionIconButton(
      {required this.icon, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05)),
          child: Icon(icon,
              size: 18, color: isDark ? Colors.white70 : Colors.black87)));
}

class _PrimaryChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryChipButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient:
                  LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Outfit'))
          ])));
}

class _FAB extends StatelessWidget {
  final bool enabled;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onTap;
  const _FAB(
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

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback? onTap;
  const _EmptyCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.cs,
      required this.isDark,
      this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.08)),
                child: Icon(icon, size: 48, color: cs.primary)),
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black45))
            ]
          ])));
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _StyledTextField({required this.controller, required this.hint});
  @override
  Widget build(BuildContext context) => TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.1)));
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isBold;
  const _SummaryRow(
      {required this.label,
      required this.value,
      required this.color,
      this.isBold = false});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: color))
      ]);
}

class _LoadingSkeleton extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  const _LoadingSkeleton({required this.isDark, required this.cs});
  @override
  Widget build(BuildContext context) {
    final base = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.02);
    return Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: SingleChildScrollView(
            child: Column(children: [
          Container(height: 240, width: double.infinity, color: Colors.white),
          const SizedBox(height: 24),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                        height: 112,
                        child: ListView.builder(
                            itemCount: 4,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (_, __) => Container(
                                width: 72,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white)))),
                    const SizedBox(height: 32),
                    Container(
                        height: 20,
                        width: 140,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    ...List.generate(
                        3,
                        (i) => Container(
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white)))
                  ]))
        ])));
  }
}

class _HistoryTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;
  const _HistoryTab(
      {required this.label,
      required this.active,
      required this.onTap,
      required this.isDark,
      required this.cs});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutExpo,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: active
                  ? LinearGradient(
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.85)])
                  : null,
              color: active ? null : Colors.transparent,
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: cs.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]
                  : []),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                  color: active
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black38),
                  letterSpacing: 0.2,
                  fontFamily: 'Outfit'))));
}

class _SettleUpCard extends StatelessWidget {
  final AppState state;
  final ColorScheme cs;
  final bool isDark;
  final AppStrings s;
  final NumberFormat fmt;
  final VoidCallback onSettleTap;
  const _SettleUpCard(
      {required this.state,
      required this.cs,
      required this.isDark,
      required this.s,
      required this.fmt,
      required this.onSettleTap});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(colors: [
                    cs.primary.withValues(alpha: 0.15),
                    cs.primary.withValues(alpha: 0.05)
                  ]),
                  border: Border.all(
                      color: cs.primary.withValues(alpha: 0.25), width: 1.5)),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary.withValues(alpha: 0.2)),
                    child: Icon(Icons.auto_awesome_rounded,
                        color: cs.primary, size: 24)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(s.settlement,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                              fontFamily: 'Outfit')),
                      Text(
                          '${state.settlements.length} ${s.settleNow.toLowerCase()}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Outfit'))
                    ])),
                ElevatedButton(
                    onPressed: onSettleTap,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text(s.settleNow,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            fontFamily: 'Outfit')))
              ]))));
}
