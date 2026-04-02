import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../l10n/strings.dart';
import 'ui_helpers.dart';

class GroupManagementScreen extends StatelessWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      body: Stack(
        children: [
          if (isDark) ...[
            _ambientGlow(top: -100, right: -100, color: cs.primary, opacity: 0.15, size: 400),
            _ambientGlow(bottom: 100, left: -100, color: Colors.purpleAccent, opacity: 0.1, size: 350),
          ] else ...[
            _ambientGlow(top: -100, right: -100, color: cs.primary, opacity: 0.1, size: 400),
          ],
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () => Navigator.pop(context)),
                flexibleSpace: FlexibleSpaceBar(
                    title: Text(s.adminGroups,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            fontFamily: 'Outfit')),
                    centerTitle: true),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              label: s.addGroup,
                              sublabel: 'New local group',
                              icon: Icons.add_rounded,
                              color: cs.primary,
                              onTap: () => _showCreateGroup(context, state),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              label: 'Join Group',
                              sublabel: 'Use invite code',
                              icon: Icons.group_add_rounded,
                              color: Colors.orangeAccent,
                              onTap: () => _showJoinGroup(context, state),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.groups.length,
                        itemBuilder: (ctx, i) {
                          final group = state.groups[i];
                          final isSelected = group.id == state.activeGroupId;
                          return _GroupCard(
                            group: group,
                            isSelected: isSelected,
                            isDark: isDark,
                            cs: cs,
                            s: s,
                            onTap: () {
                              state.switchGroup(group.id);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${s.switchedTo} ${group.name}'),
                                  behavior: SnackBarBehavior.floating));
                            },
                            onEdit: () => _showEditGroupName(context, state, group, s),
                            onDelete: () => _showDeleteGroupConfirm(context, state, group, s),
                            onSync: () async {
                              if (group.syncId == null) {
                                await state.enableSync();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Firebase Sync Enabled!'),
                                    behavior: SnackBarBehavior.floating));
                              } else {
                                await Clipboard.setData(ClipboardData(text: group.syncId!));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Invite code copied to clipboard!'),
                                    behavior: SnackBarBehavior.floating));
                              }
                            },
                          );
                        },
                      ),
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

  void _showCreateGroup(BuildContext context, AppState state) {
    final s = AppStrings.of(context);
    final ctrl = TextEditingController();
    UIHelpers.showLiquidDialog(
        context: context,
        title: s.newGroupName,
        content: _StyledTextField(controller: ctrl, hint: 'e.g. Travel 2024'),
        confirmLabel: s.add,
        onConfirm: () => state.createGroup(ctrl.text.trim()));
  }

  void _showJoinGroup(BuildContext context, AppState state) {
    final ctrl = TextEditingController();
    UIHelpers.showLiquidDialog(
        context: context,
        title: 'Join Synced Group',
        content: _StyledTextField(controller: ctrl, hint: 'Enter Invite Code (ID)'),
        confirmLabel: 'Join',
        onConfirm: () => state.joinSyncGroup(ctrl.text.trim()));
  }

  void _showEditGroupName(BuildContext context, AppState state, Group group, AppStrings s) {
    final ctrl = TextEditingController(text: group.name);
    UIHelpers.showLiquidDialog(
        context: context,
        title: s.editName,
        content: _StyledTextField(controller: ctrl, hint: s.editName),
        confirmLabel: s.save,
        onConfirm: () => state.setGroupName(group.id, ctrl.text.trim()));
  }

  void _showDeleteGroupConfirm(BuildContext context, AppState state, Group group, AppStrings s) {
    if (state.groups.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('At least one group must be maintained.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (!state.isGroupBalanced(group.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All members must have 0 balance to delete this group.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    UIHelpers.showLiquidDialog(
        context: context,
        title: s.deleteGroupConfirm,
        content: Text(s.deleteGroupMsg, style: TextStyle(color: Colors.grey.shade500)),
        confirmLabel: s.delete,
        isDestructive: true,
        onConfirm: () => state.deleteGroup(group.id));
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
            child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      color.withValues(alpha: opacity),
                      Colors.transparent
                    ])))));
  }
}

class _ActionCard extends StatelessWidget {
  final String label, sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.label,
      required this.sublabel,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.8)]),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                  child: Icon(icon, color: Colors.white, size: 24)),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Outfit')),
              Text(sublabel,
                  style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final bool isSelected, isDark;
  final ColorScheme cs;
  final AppStrings s;
  final VoidCallback onTap, onEdit, onDelete, onSync;
  const _GroupCard(
      {required this.group,
      required this.isSelected,
      required this.isDark,
      required this.cs,
      required this.s,
      required this.onTap,
      required this.onEdit,
      required this.onDelete,
      required this.onSync});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.1)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                    border: Border.all(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.3)
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        width: isSelected ? 1.5 : 0.5)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: cs.primary.withValues(alpha: 0.1)),
                            child: Icon(
                                group.syncId != null ? Icons.cloud_done_rounded : Icons.folder_rounded,
                                color: cs.primary,
                                size: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(group.name,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                        fontFamily: 'Outfit'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (group.syncId != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(Icons.sync_rounded, color: Colors.blueAccent, size: 14),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${group.people.length} ${s.people} • ${group.transactions.length} txs',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  fontWeight: FontWeight.w600))
                        ])),
                        if (isSelected)
                          Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                              child: const Icon(Icons.check, color: Colors.white, size: 12)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      _CompactActionIcon(
                        icon: group.syncId == null ? Icons.cloud_upload_outlined : Icons.share_rounded,
                        onTap: onSync,
                        isDark: isDark,
                        color: group.syncId == null ? Colors.blue : Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      _CompactActionIcon(icon: Icons.edit_rounded, onTap: onEdit, isDark: isDark),
                      if (context.read<AppState>().groups.length > 1) ...[
                        const SizedBox(width: 8),
                        _CompactActionIcon(
                            icon: Icons.delete_outline_rounded,
                            onTap: onDelete,
                            isDark: isDark,
                            isDestructive: true)
                      ]
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _CompactActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;
  final Color? color;
  const _CompactActionIcon(
      {required this.icon,
      required this.onTap,
      required this.isDark,
      this.isDestructive = false,
      this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.1)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))),
          child: Icon(icon,
              size: 18,
              color: isDestructive
                  ? Colors.red
                  : (color ?? (isDark ? Colors.white70 : Colors.black54)))));
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.1)));
}
