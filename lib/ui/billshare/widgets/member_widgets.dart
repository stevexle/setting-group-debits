import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../models.dart';
import '../../../state/app_state.dart';
import '../../../l10n/strings.dart';
import '../../ui_helpers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/modals/member_modals.dart';

class MemberCell extends StatelessWidget {
  final Person person;
  final double paid, share, net;
  final AppStrings s;
  final ColorScheme cs;
  final bool isOwner;

  const MemberCell({
    super.key,
    required this.person,
    required this.paid,
    required this.share,
    required this.net,
    required this.s,
    required this.cs,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarColor = UIHelpers.getAvatarColor(person.colorIndex);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showPersonSummary(context, person, paid, share, net, s,
            NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0));
      },
      onLongPress: () {
        if (!state.isOwner) {
          HapticFeedback.vibrate();
          return;
        }

        HapticFeedback.heavyImpact();
        if (person.id == state.me?.id) {
          UIHelpers.showLiquidDialog(
            context: context,
            title: s.cannotClear,
            content: Text(s.cannotDeleteSelf),
            confirmLabel: s.understood,
            onConfirm: () {},
          );
        } else if (state.isPersonInvolvedInTransactions(person.id)) {
          UIHelpers.showLiquidDialog(
            context: context,
            title: s.cannotDeleteMember,
            content: Text(s.deleteMemberMsg),
            confirmLabel: s.understood,
            onConfirm: () {},
          );
        } else {
          confirmRemovePerson(context, person, s);
        }
      },
      onDoubleTap: () {
        if (!state.canEditPerson(person)) {
          HapticFeedback.vibrate();
          return;
        }
        HapticFeedback.mediumImpact();
        showAddMember(context, s, existingPerson: person);
      },
      child: RepaintBoundary(
        child: Container(
          width: 72,
          margin: const EdgeInsets.only(right: 10),
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                    width: 36,
                    height: 36,
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
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]),
                    child: person.avatarUrl.isEmpty ||
                            (!person.avatarUrl.startsWith('http') &&
                                !File(person.avatarUrl).existsSync())
                        ? Center(
                            child: Text(person.name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)))
                        : null),
                if (isOwner)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 9,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  )),
            ),
            const SizedBox(height: 2),
            StatusChip(net: net, cs: cs)
          ]),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final double net;
  final ColorScheme cs;

  const StatusChip({super.key, required this.net, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isMatched = net.abs() < 0.01;
    final color = isMatched ? Colors.grey : (net > 0 ? Colors.green : cs.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color.withValues(alpha: 0.1)),
      child: Text(
        isMatched ? '0' : '${net > 0 ? '+' : ''}${net.toInt()}',
        style:
            TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}

class MemberSection extends StatelessWidget {
  final List<Person> people;
  final String? ownerId;
  final Map<String, double> netBalances;
  final Map<String, double> paidBalances;
  final Map<String, double> shareBalances;
  final AppStrings s;
  final ColorScheme cs;

  const MemberSection({
    super.key,
    required this.people,
    this.ownerId,
    required this.netBalances,
    required this.paidBalances,
    required this.shareBalances,
    required this.s,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return EmptyCard(message: s.noMembers, icon: Icons.person_add_rounded);
    }
    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: people.length,
        itemBuilder: (ctx, i) {
          final p = people[i];
          final net = netBalances[p.id] ?? 0.0;
          final paid = paidBalances[p.id] ?? 0.0;
          final share = shareBalances[p.id] ?? 0.0;
          final isOwner = (p.userId != null && p.userId == ownerId);

          return MemberCell(
              person: p, paid: paid, share: share, net: net, s: s, cs: cs, isOwner: isOwner);
        },
      ),
    );
  }
}
