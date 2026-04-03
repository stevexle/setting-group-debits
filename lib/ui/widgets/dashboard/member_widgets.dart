import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../models.dart';
import '../../../state/app_state.dart';
import '../../../l10n/strings.dart';
import '../../ui_helpers.dart';
import 'common_widgets.dart';

void showAddMember(BuildContext context, AppStrings s, {Person? existingPerson}) {
  final ctrl = TextEditingController(text: existingPerson?.name);
  final state = context.read<AppState>();
  int selectedColor =
      existingPerson?.colorIndex ?? (DateTime.now().millisecondsSinceEpoch % 8);
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
                final image_picker.XFile? image = await picker.pickImage(
                    source: image_picker.ImageSource.gallery);
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(8, (i) {
                  final color = UIHelpers.getAvatarColor(i);
                  final selected = selectedColor == i;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
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

void confirmRemovePerson(BuildContext context, Person person, AppStrings s) {
  final state = context.read<AppState>();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  UIHelpers.showLiquidDialog(
    context: context,
    title: s.deleteMember,
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
                    text: ' ${person.name} ',
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
                child: Text(s.deleteMemberMsg,
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
    onConfirm: () => state.removePerson(person.id),
  );
}

class MemberCell extends StatelessWidget {
  final Person person;
  final double paid, share, net;
  final AppStrings s;
  final ColorScheme cs;

  const MemberCell({
    super.key,
    required this.person,
    required this.paid,
    required this.share,
    required this.net,
    required this.s,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarColor = UIHelpers.getAvatarColor(person.colorIndex);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showPersonSummary(context, person, paid, share, net, s, NumberFormat.currency(locale: 'vi_VN', symbol: '₫'));
      },
      onLongPress: () {
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
            title: s.cannotDeleteLastGroup.replaceAll('nhóm cuối cùng', 'thành viên này'), 
            content: Text(s.deleteMemberMsg),
            confirmLabel: s.understood,
            onConfirm: () {},
          );
        } else {
          confirmRemovePerson(context, person, s);
        }
      },
      onDoubleTap: () {
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
            const SizedBox(height: 6),
            Text(person.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    fontFamily: 'Outfit')),
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
        style: TextStyle(
            fontSize: 8, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}

class MemberSection extends StatelessWidget {
  final List<Person> people;
  final Map<String, double> netBalances;
  final Map<String, double> paidBalances;
  final Map<String, double> shareBalances;
  final AppStrings s;
  final ColorScheme cs;

  const MemberSection({
    super.key,
    required this.people,
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
          
          return MemberCell(
            person: p, 
            paid: paid,
            share: share,
            net: net, 
            s: s, 
            cs: cs
          );
        },
      ),
    );
  }
}

void showPersonSummary(BuildContext context, Person person, double paid, double share, double net, AppStrings s, NumberFormat fmt) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final accentColor = UIHelpers.getAvatarColor(person.colorIndex);
      
      return Container(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E1A), // Strict dark background like the image
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with initial
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.15),
                border: Border.all(color: accentColor.withValues(alpha: 0.1), width: 1),
                image: person.avatarUrl.isNotEmpty
                    ? (person.avatarUrl.startsWith('http')
                        ? DecorationImage(image: NetworkImage(person.avatarUrl), fit: BoxFit.cover)
                        : (File(person.avatarUrl).existsSync()
                            ? DecorationImage(image: FileImage(File(person.avatarUrl)), fit: BoxFit.cover)
                            : null))
                    : null,
              ),
              child: person.avatarUrl.isEmpty || 
                     (!person.avatarUrl.startsWith('http') && !File(person.avatarUrl).existsSync())
                  ? Center(
                      child: Text(
                        person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: accentColor, fontFamily: 'Outfit'),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              person.name, 
              style: const TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.w900, 
                fontFamily: 'Outfit',
                color: Colors.white,
                letterSpacing: -0.5,
              )
            ),
            const SizedBox(height: 32),
            
            // Financial Stats Rows
            _buildStatRow(s.totalPaid, paid, const Color(0xFF66BB6A), fmt),
            const SizedBox(height: 16),
            _buildStatRow(s.yourShare, share, const Color(0xFFFFA726), fmt),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),
            _buildStatRow(s.tabBill, net, Colors.white, fmt, isNet: true),
            
            const SizedBox(height: 40),
            
            // Stadium Edit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showAddMember(context, s, existingPerson: person);
                },
                icon: Icon(Icons.edit_rounded, color: accentColor, size: 20),
                label: Text(
                  s.edit.toUpperCase(),
                  style: TextStyle(
                    color: accentColor, 
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.2,
                    fontFamily: 'Outfit'
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1.5),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }
  );
}

Widget _buildStatRow(String label, double value, Color color, NumberFormat fmt, {bool isNet = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        isNet ? "Net balance" : label, // Use English "Net balance" as requested by image
        style: TextStyle(
          fontSize: 16, 
          fontWeight: isNet ? FontWeight.w800 : FontWeight.w600, 
          color: isNet ? Colors.white70 : Colors.white54,
          fontFamily: 'Outfit'
        ),
      ),
      Text(
        fmt.format(value),
        style: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.w900, 
          color: color, 
          fontFamily: 'Outfit',
          decoration: isNet ? TextDecoration.underline : null,
          decorationColor: color,
        ),
      ),
    ],
  );
}
