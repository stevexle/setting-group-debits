import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/navigation_state.dart';
import '../models.dart';
import '../l10n/strings.dart';
import 'ui_helpers.dart';
import 'widgets/common_widgets.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final _idController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MainScreenScaffold(
      title: s.myGroups,
      fab: null,
      children: [
        _buildJoinCreateCard(context, state, s, cs, isDark),
        const SizedBox(height: 24),
        if (state.groups.isEmpty)
          EmptyCard(icon: Icons.group_off_rounded, message: s.noGroupsYet)
        else if (MediaQuery.of(context).size.width > 600)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 0,
            childAspectRatio: 2.2,
            children: state.groups
                .map((group) =>
                    _buildGroupCard(context, state, group, s, cs, isDark))
                .toList(),
          )
        else
          ...state.groups.map(
              (group) => _buildGroupCard(context, state, group, s, cs, isDark)),
        if (_isJoining)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: GlassContainer(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildJoinCreateCard(BuildContext context, AppState state,
      AppStrings s, ColorScheme cs, bool isDark) {
    return SummaryActionCard(
      title: s.joinOrCreate,
      children: [
        Row(
          children: [
            Expanded(
                child: StyledTextField(
                    controller: _idController, hint: s.inviteCodeHint)),
            const SizedBox(width: 8),
            PrimaryChipButton(
              label: s.join,
              icon: Icons.login_rounded,
              color: cs.primary,
              onTap: () async {
                final id = _idController.text.trim();
                if (id.isNotEmpty) {
                  setState(() => _isJoining = true);
                  try {
                    await state.joinSyncGroup(id);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(s.failedToJoin),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating),
                    );
                  } finally {
                    if (mounted) setState(() => _isJoining = false);
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Colors.white10),
        const SizedBox(height: 10),
        Center(
          child: PrimaryChipButton(
            label: s.addGroup,
            icon: Icons.add_rounded,
            color: const Color(0xFF10B981),
            onTap: () => _showCreateDialog(context, state, s),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, AppState state, Group group,
      AppStrings s, ColorScheme cs, bool isDark) {
    final isSelected = group.id == state.activeGroupId;
    final inviteCode = group.syncId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(10),
        border: Border.all(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          width: isSelected ? 1.5 : 1.0,
        ),
        child: InkWell(
          onTap: () {
            state.switchGroup(group.id);
            context
                .read<TabNavigationState>()
                .setTab(0); // Switch to BillShare Settlement
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? cs.primary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: cs.primary, size: 18),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (ctx) {
                      final isBalanced = state.isGroupBalanced(group.id);
                      final canDelete = state.groups.length > 1 && isBalanced;
                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: canDelete
                              ? Colors.redAccent.withValues(alpha: 0.8)
                              : (isDark ? Colors.white10 : Colors.black12),
                        ),
                        onPressed: () =>
                            _handleDeleteGroup(context, state, group, s),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 10,
                      color: isDark ? Colors.white38 : Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    '${group.people.length} ${s.membersCount}',
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  _buildTypeChip(group.type, s, cs, isDark),
                ],
              ),
              if (inviteCode != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.inviteCode,
                              style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: cs.primary.withValues(alpha: 0.7),
                                  letterSpacing: 0.8),
                            ),
                            Text(
                              inviteCode,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.copy_rounded,
                            size: 14, color: Colors.white38),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(s.codeCopied),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(
      GroupType type, AppStrings s, ColorScheme cs, bool isDark) {
    String label;
    IconData icon;
    Color color;

    switch (type) {
      case GroupType.settlement:
        label = s.groupTypeSettlement;
        icon = Icons.payments_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case GroupType.planning:
        label = s.groupTypePlanning;
        icon = Icons.luggage_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case GroupType.asset:
        label = s.groupTypeAsset;
        icon = Icons.account_balance_rounded;
        color = const Color(0xFF10B981);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AppState state, AppStrings s) {
    final ctrl = TextEditingController();
    GroupType selectedType = GroupType.settlement;

    UIHelpers.showLiquidDialog(
      context: context,
      title: s.newGroup,
      content: StatefulBuilder(builder: (context, setDialogState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StyledTextField(controller: ctrl, hint: s.groupNameHint),
            const SizedBox(height: 20),
            Text(
              s.groupTypeLabel,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Row(
              children: GroupType.values.map((type) {
                final isSelected = selectedType == type;
                String label;
                IconData icon;
                Color color;
                switch (type) {
                  case GroupType.settlement:
                    label = s.groupTypeSettlement;
                    icon = Icons.payments_rounded;
                    color = const Color(0xFF3B82F6);
                    break;
                  case GroupType.planning:
                    label = s.groupTypePlanning;
                    icon = Icons.luggage_rounded;
                    color = const Color(0xFFF59E0B);
                    break;
                  case GroupType.asset:
                    label = s.groupTypeAsset;
                    icon = Icons.account_balance_rounded;
                    color = const Color(0xFF10B981);
                    break;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setDialogState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            Icon(icon,
                                size: 20,
                                color: isSelected ? color : Colors.grey),
                            const SizedBox(height: 4),
                            Text(label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.normal,
                                    color: isSelected ? color : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }),
      confirmLabel: s.create,
      onConfirm: () => state.createGroup(ctrl.text.trim(), type: selectedType),
    );
  }

  void _handleDeleteGroup(
      BuildContext context, AppState state, Group group, AppStrings s) {
    if (state.groups.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(s.cannotDeleteLastGroup),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (!state.isGroupBalanced(group.id)) {
      UIHelpers.showLiquidDialog(
        context: context,
        title: s.cannotClear,
        content: Text(s.outstandingDebtsError,
            style: const TextStyle(
                color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        confirmLabel: s.understood,
        onConfirm: () {},
      );
      return;
    }

    UIHelpers.showLiquidDialog(
      context: context,
      title: s.deleteGroupConfirm,
      content: Text(s.deleteGroupConfirmMsg.replaceAll('{name}', group.name),
          style: const TextStyle(
              color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
      confirmLabel: s.delete,
      isDestructive: true,
      onConfirm: () => state.deleteGroup(group.id),
    );
  }
}
