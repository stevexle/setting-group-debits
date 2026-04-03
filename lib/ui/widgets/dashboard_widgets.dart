import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../ui_helpers.dart';
import '../add_transaction_modal.dart';

class DashboardStatsCard extends StatelessWidget {
  final AppState state;
  final ColorScheme cs;
  final bool isDark;
  final AppStrings s;
  final NumberFormat fmt;
  const DashboardStatsCard(
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
                StatItem(
                    label: s.totalMembers,
                    value: '${state.people.length}',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF00D4FF)),
                _vDivider(isDark),
                StatItem(
                    label: s.thisWeek,
                    value: _short(state.weeklyTotal),
                    icon: Icons.insights_rounded,
                    color: const Color(0xFF7B61FF)),
                _vDivider(isDark),
                StatItem(
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

class StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const StatItem(
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

class MembersRow extends StatelessWidget {
  final AppState state;
  final AppStrings s;
  final ColorScheme cs;
  final bool isDark;
  final NumberFormat fmt;
  final Function showAddMember;
  final Function showPersonSummary;
  final Function confirmRemovePerson;

  const MembersRow({
    required this.state,
    required this.s,
    required this.cs,
    required this.isDark,
    required this.fmt,
    required this.showAddMember,
    required this.showPersonSummary,
    required this.confirmRemovePerson,
  });

  @override
  Widget build(BuildContext context) {
    if (state.people.isEmpty)
      return EmptyCard(
          icon: Icons.group_add_rounded,
          title: s.noMembers,
          subtitle: s.noMembersSubtitle,
          cs: cs,
          isDark: isDark,
          onTap: () => showAddMember(context, s));
    return SizedBox(
        height: 112,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: state.people.length + 1,
            itemBuilder: (context, i) => i == state.people.length
                ? AddMemberCell(
                    onTap: () => showAddMember(context, s),
                    cs: cs,
                    isDark: isDark,
                    label: s.addMember)
                : MemberCell(
                    person: state.people[i],
                    net: state.getPersonNetBalance(state.people[i].id),
                    isDark: isDark,
                    cs: cs,
                    s: s,
                    showPersonSummary: showPersonSummary,
                    confirmRemovePerson: confirmRemovePerson,
                  )));
  }
}

class AddMemberCell extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isDark;
  final String label;
  const AddMemberCell(
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

class MemberCell extends StatelessWidget {
  final Person person;
  final double net;
  final bool isDark;
  final ColorScheme cs;
  final AppStrings s;
  final Function showPersonSummary;
  final Function confirmRemovePerson;

  const MemberCell({
    required this.person,
    required this.net,
    required this.isDark,
    required this.cs,
    required this.s,
    required this.showPersonSummary,
    required this.confirmRemovePerson,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = UIHelpers.getAvatarColor(person.colorIndex);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final state = context.read<AppState>();

    return GestureDetector(
      onTap: () => showPersonSummary(context, person, s, state, fmt),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        confirmRemovePerson(context, person, s);
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
                  gradient: person.avatarUrl.isEmpty
                      ? LinearGradient(colors: [
                          avatarColor,
                          avatarColor.withValues(alpha: 0.7)
                        ])
                      : null,
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
                  boxShadow: [
                    BoxShadow(
                        color: avatarColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]),
              child: person.avatarUrl.isEmpty ||
                      (!person.avatarUrl.startsWith('http') &&
                          !File(person.avatarUrl).existsSync())
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
          StatusChip(net: net, cs: cs)
        ]),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final double net;
  final ColorScheme cs;
  const StatusChip({required this.net, required this.cs});

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

class SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme cs;
  final bool isDark;
  const SectionLabel(
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

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const ActionIconButton(
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

class PrimaryChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const PrimaryChipButton(
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

class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback? onTap;
  const EmptyCard(
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

class SettleUpCard extends StatelessWidget {
  final AppState state;
  final ColorScheme cs;
  final bool isDark;
  final AppStrings s;
  final NumberFormat fmt;
  final VoidCallback onSettleTap;
  const SettleUpCard(
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

class HistoryTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;
  const HistoryTab(
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

class LoadingSkeleton extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  const LoadingSkeleton({required this.isDark, required this.cs});

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

class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const StyledTextField({required this.controller, required this.hint});

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

class SummaryRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isBold;
  const SummaryRow(
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

class DateGroup extends StatelessWidget {
  final String dateLabel;
  final List<Transaction> txs;
  final AppState state;
  final ColorScheme cs;
  final bool isDark;
  final NumberFormat fmt;
  final AppStrings s;
  const DateGroup(
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
        ...txs.map((tx) => TransactionCard(
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

class TransactionCard extends StatelessWidget {
  final Transaction tx;
  final Person payer;
  final NumberFormat fmt;
  final ColorScheme cs;
  final bool isDark;
  final AppStrings s;
  final AppState state;
  const TransactionCard(
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
                          image: !tx.isPayment && personHasAvatar(payer)
                              ? (payer.avatarUrl.startsWith('http')
                                  ? DecorationImage(
                                      image: NetworkImage(payer.avatarUrl),
                                      fit: BoxFit.cover)
                                  : (File(payer.avatarUrl).existsSync()
                                      ? DecorationImage(
                                          image: FileImage(File(payer.avatarUrl)),
                                          fit: BoxFit.cover)
                                      : null))
                              : null),
                      child: tx.isPayment || !personHasAvatar(payer)
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
                            if (tx.updatedAt != null) ...[
                               const SizedBox(width: 6),
                               Container(
                                 padding: const EdgeInsets.symmetric(
                                     horizontal: 5, vertical: 1),
                                 decoration: BoxDecoration(
                                     borderRadius: BorderRadius.circular(4),
                                     color: Colors.blue.withValues(alpha: 0.1),
                                     border: Border.all(
                                         color: Colors.blue.withValues(alpha: 0.25))),
                                 child: Text(s.edited,
                                     style: const TextStyle(
                                         fontSize: 7,
                                         fontWeight: FontWeight.w900,
                                         color: Colors.blue)),
                               ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '${DateFormat('HH:mm').format(tx.date)}${tx.updatedAt != null ? ' (${s.editedAt} ${DateFormat(tx.updatedAt!.day != tx.date.day ? 'HH:mm dd/MM' : 'HH:mm').format(tx.updatedAt!)})' : ''} • ${tx.isPayment ? s.tabBill : '${s.paidBy} ${payer.name} • ${tx.participantIds.length} ${s.people}'}',
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

  bool personHasAvatar(Person p) {
    return p.avatarUrl.isNotEmpty &&
        (p.avatarUrl.startsWith('http') || File(p.avatarUrl).existsSync());
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
