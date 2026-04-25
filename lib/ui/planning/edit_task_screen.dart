import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../l10n/strings.dart';
import '../ui_helpers.dart';
import '../widgets/base/glass_container.dart';
import '../widgets/base/liquid_background.dart';
import 'widgets/liquid_pickers.dart';

class EditTaskScreen extends StatefulWidget {
  final BudgetPlan plan;
  final PlanTask task;
  const EditTaskScreen({super.key, required this.plan, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController costController;
  late TextEditingController noteController;
  late TextEditingController dueDateController;
  late TextEditingController contactController;
  late PlanPriority selectedPriority;
  String? selectedAssigneeId;
  DateTime? selectedDueDate;
  late Category selectedCategory;

  @override
  void initState() {
    super.initState();
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
    titleController = TextEditingController(text: widget.task.title);
    costController = TextEditingController(text: fmt.format(widget.task.estimatedCost).trim());
    noteController = TextEditingController(text: widget.task.note ?? '');
    contactController = TextEditingController(text: widget.task.contact ?? '');
    selectedPriority = widget.task.priority;
    selectedAssigneeId = widget.task.assignedTo;
    selectedDueDate = widget.task.dueDate;
    selectedCategory = widget.task.category;
    dueDateController = TextEditingController(
      text: selectedDueDate != null ? '${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}' : '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    // Get group if linked
    Group? linkedGroup;
    if (widget.plan.linkedGroupId != null) {
      try {
        linkedGroup = context.read<AppState>().groups.firstWhere((g) => g.id == widget.plan.linkedGroupId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.editItem,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _onDelete,
          ),
        ],
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const SizedBox(height: 20),
                   _buildPrioritySelector(s, isDark, cs),
                   const SizedBox(height: 24),
                   GlassContainer(
                     padding: const EdgeInsets.all(24),
                     child: Column(
                       children: [
                          _buildField(titleController, s.name, Icons.task_alt_rounded, isDark, cs),
                          const SizedBox(height: 16),
                          _buildField(
                            dueDateController, 
                            s.dueDateHint, 
                            Icons.calendar_today_rounded, 
                            isDark, cs,
                            readOnly: true,
                            onTap: () async {
                              await showLiquidDatePicker(
                                context,
                                initialDate: selectedDueDate ?? DateTime.now(),
                                onDatePicked: (date) {
                                  setState(() {
                                    selectedDueDate = date;
                                    dueDateController.text = '${date.day}/${date.month}/${date.year}';
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildField(contactController, s.contactHint, Icons.contact_phone_rounded, isDark, cs),
                          const SizedBox(height: 16),
                          _buildField(noteController, s.notesHint, Icons.notes_rounded, isDark, cs),
                          const SizedBox(height: 16),
                          _buildField(costController, s.amountHint, Icons.bolt_rounded, isDark, cs, isNumber: true),
                       ],
                     ),
                   ),
                   const SizedBox(height: 32),
                   _buildCategoryPicker(s, isDark, cs),
                   const SizedBox(height: 32),
                   if (linkedGroup != null) ...[
                     _buildAssigneePicker(linkedGroup, s, isDark, cs),
                     const SizedBox(height: 32),
                   ],
                   const SizedBox(height: 16),
                   SizedBox(
                     width: double.infinity,
                     child: Container(
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(24),
                         boxShadow: [
                           BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                         ],
                       ),
                       child: ElevatedButton(
                         onPressed: _onSave,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: cs.primary,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 22),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                           elevation: 0,
                         ),
                         child: Text(s.save.toUpperCase(),
                             style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
                       ),
                     ),
                   ),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(AppStrings s, bool isDark, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MỨC ĐỘ ƯU TIÊN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          children: PlanPriority.values.map((p) {
            final isSelected = selectedPriority == p;
            final color = _getPriorityColor(p);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedPriority = p),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(p.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isSelected ? color : (isDark ? Colors.white38 : Colors.black38))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssigneePicker(Group group, AppStrings s, bool isDark, ColorScheme cs) {
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
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildMemberAvatar(
                onTap: () => setState(() => selectedAssigneeId = null),
                isSelected: selectedAssigneeId == null,
                icon: Icons.person_off_rounded,
                label: s.noAssignee,
                cs: cs,
                isDark: isDark,
              ),
              ...group.people.map((p) => _buildMemberAvatar(
                    onTap: () => setState(() => selectedAssigneeId = p.id),
                    isSelected: selectedAssigneeId == p.id,
                    person: p,
                    cs: cs,
                    isDark: isDark,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAvatar(
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
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 16),
        curve: Curves.easeOutBack,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accentColor.withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                border: Border.all(
                    color: isSelected
                        ? (person != null ? accentColor : cs.primary)
                        : Colors.transparent,
                    width: 3),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: (person != null ? accentColor : cs.primary)
                                .withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ]
                    : null,
              ),
              child: Center(
                child: person != null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            person.avatarUrl.isEmpty ? accentColor : null,
                        backgroundImage: person.avatarUrl.isNotEmpty
                            ? (person.avatarUrl.startsWith('http')
                                ? NetworkImage(person.avatarUrl)
                                : (File(person.avatarUrl).existsSync()
                                    ? FileImage(File(person.avatarUrl))
                                    : null))
                            : null,
                        child: person.avatarUrl.isEmpty
                            ? Text(person.name[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900))
                            : null,
                      )
                    : Icon(icon,
                        size: 24,
                        color: isSelected
                            ? cs.primary
                            : (isDark ? Colors.white38 : Colors.black38)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (person?.name ?? label ?? '').split(' ').first,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white38 : Colors.black38)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker(AppStrings s, bool isDark, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.category.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: Category.values.map((cat) {
              final isSelected = selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? cs.primary : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(UIHelpers.getCategoryIcon(cat), size: 16, color: isSelected ? cs.primary : (isDark ? Colors.white38 : Colors.black38)),
                      const SizedBox(width: 8),
                      Text(
                        UIHelpers.getCategoryName(cat, s),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, bool isDark, ColorScheme cs, {bool readOnly = false, VoidCallback? onTap, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber ? [CurrencyInputFormatter()] : null,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
          prefixIcon: Icon(icon, color: cs.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Color _getPriorityColor(PlanPriority p) {
    switch (p) {
      case PlanPriority.high: return const Color(0xFFFF3B30);
      case PlanPriority.medium: return const Color(0xFFFF9500);
      case PlanPriority.low: return const Color(0xFF34C759);
    }
  }

  void _onSave() {
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    context.read<AppState>().updatePlanTask(
          widget.plan.id,
          widget.task.copyWith(
            title: title,
            priority: selectedPriority,
            assignedTo: selectedAssigneeId,
            contact: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
            estimatedCost: double.tryParse(costController.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
            category: selectedCategory,
            dueDate: selectedDueDate,
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          ),
        );
    Navigator.pop(context);
  }

  void _onDelete() {
    context.read<AppState>().removePlanTask(widget.plan.id, widget.task.id);
    Navigator.pop(context);
  }
}
