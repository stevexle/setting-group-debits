import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../ui_helpers.dart';
import '../../widgets/common_widgets.dart';
import '../edit_itinerary_screen.dart';

void showItineraryDetailModal(BuildContext context, AppStrings s, BudgetPlan plan, PlanItineraryItem item) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cs = Theme.of(context).colorScheme;
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, -10))],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text('Ngày ${item.day}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Text(item.time, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(item.activity, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, height: 1.1)),
                    if (item.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 16, color: cs.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(item.location!, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      Text(s.notesHint, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Text(item.note!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    if (item.socialLinks.isNotEmpty) ...[
                      Text("Tham khảo", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                      const SizedBox(height: 12),
                      Row(
                        children: item.socialLinks.map((url) {
                          IconData icon = Icons.link_rounded;
                          Color color = cs.primary;
                          if (url.contains('tiktok.com')) { icon = Icons.music_note_rounded; color = Colors.pinkAccent; }
                          else if (url.contains('facebook.com') || url.contains('fb.com')) { icon = Icons.facebook_rounded; color = const Color(0xFF1877F2); }
                          else if (url.contains('youtube.com') || url.contains('youtu.be')) { icon = Icons.video_library_rounded; color = const Color(0xFFFF0000); }
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: IconButton.filled(
                              onPressed: () => UIHelpers.openUrl(url),
                              icon: Icon(icon, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: color.withValues(alpha: 0.15),
                                foregroundColor: color,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dự chi', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
                            Text(fmt.format(item.estimatedCost), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cs.primary)),
                          ],
                        ),
                        if (item.mapLink != null)
                          ElevatedButton.icon(
                            onPressed: () => UIHelpers.openUrl(item.mapLink),
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: const Text('Mở Bản Đồ', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => EditItineraryScreen(plan: plan, item: item)));
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: Text(s.editItem),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white12 : Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void confirmDeletePlan(BuildContext context, AppStrings s, BudgetPlan plan) {
  showDialog(
    context: context,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: GlassContainer(
          borderRadius: 32,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                s.deleteItem,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.confirmDeletePlanMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        s.cancel,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AppState>().removePlan(plan.id);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        s.delete,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void onToggleTask(BuildContext context, PlanTask task, AppStrings s, BudgetPlan plan) {
  final state = context.read<AppState>();
  final newStatus = task.status == PlanTaskStatus.done
      ? PlanTaskStatus.toDo
      : PlanTaskStatus.done;
  state.updatePlanTask(plan.id, task.copyWith(status: newStatus));
}

Widget buildGroupDropdown(BuildContext context, List<Group> groups, String? selectedId, Function(String?) onChanged, AppStrings s) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = Theme.of(context).colorScheme.primary;

  return SizedBox(
    height: 70,
    child: ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      children: [
        GestureDetector(
          onTap: () => onChanged(null),
          child: Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selectedId == null ? primaryColor.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selectedId == null ? primaryColor : (isDark ? Colors.white24 : Colors.black12), width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.link_off_rounded, size: 22, color: selectedId == null ? primaryColor : (isDark ? Colors.white54 : Colors.black54)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Không\nliên kết", 
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: selectedId == null ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white70 : Colors.black54)
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
        ...groups.map((g) {
          final isSelected = g.id == selectedId;
          return GestureDetector(
            onTap: () => onChanged(g.id),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isSelected ? primaryColor : (isDark ? Colors.white24 : Colors.black12), width: 2),
                boxShadow: isSelected ? [BoxShadow(color: primaryColor.withValues(alpha: 0.15), blurRadius: 12)] : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.groups_rounded, size: 18, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      g.name,
                      style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white : Colors.black87)
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}

Widget buildMemberDropdown(BuildContext context, Group group, String? selectedMemberId, Function(String?) onChanged, AppStrings s) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cs = Theme.of(context).colorScheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(s.selectMember.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1.2)),
      const SizedBox(height: 12),
      SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildMemberChip(
              onTap: () => onChanged(null),
              isSelected: selectedMemberId == null,
              icon: Icons.person_off_rounded,
              label: s.noAssignee,
              cs: cs,
              isDark: isDark,
            ),
            ...group.people.map((p) => _buildMemberChip(
                  onTap: () => onChanged(p.id),
                  isSelected: selectedMemberId == p.id,
                  person: p,
                  cs: cs,
                  isDark: isDark,
                )),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

Widget _buildMemberChip(
    {required VoidCallback onTap,
    required bool isSelected,
    Person? person,
    IconData? icon,
    String? label,
    required ColorScheme cs,
    required bool isDark}) {
  final accentColor = person != null
      ? UIHelpers.getAvatarColor(person.colorIndex)
      : (isDark ? Colors.white24 : Colors.black26);

  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (person != null
                ? accentColor.withValues(alpha: 0.2)
                : cs.primary.withValues(alpha: 0.15))
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isSelected
                ? (person != null ? accentColor : cs.primary)
                : Colors.transparent,
            width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (person != null)
            CircleAvatar(
              radius: 12,
              backgroundColor: person.avatarUrl.isEmpty ? accentColor : null,
              backgroundImage: person.avatarUrl.isNotEmpty
                  ? (person.avatarUrl.startsWith('http')
                      ? NetworkImage(person.avatarUrl)
                      : (File(person.avatarUrl).existsSync()
                          ? FileImage(File(person.avatarUrl)) as ImageProvider
                          : null))
                  : null,
              child: person.avatarUrl.isEmpty
                  ? Text(person.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))
                  : null,
            )
          else if (icon != null)
            Icon(icon,
                size: 18,
                color: isSelected
                    ? cs.primary
                    : (isDark ? Colors.white38 : Colors.black38)),
          const SizedBox(width: 8),
          Text(
            person?.name ?? label ?? '',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white54 : Colors.black45)),
          ),
        ],
      ),
    ),
  );
}
