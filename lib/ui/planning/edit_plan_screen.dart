import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../ui_helpers.dart';
import '../widgets/common_widgets.dart';

class EditPlanScreen extends StatefulWidget {
  final BudgetPlan plan;
  const EditPlanScreen({super.key, required this.plan});

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  late TextEditingController _titleController;
  late TextEditingController _budgetController;
  late TextEditingController _linksController;
  late PlanType _selectedType;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan.title);
    _budgetController = TextEditingController(text: widget.plan.budgetTotal.toInt().toString());
    _linksController = TextEditingController(text: widget.plan.referenceLinks.join(', '));
    _selectedType = widget.plan.type;
    _selectedGroupId = widget.plan.linkedGroupId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

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
          s.editPlanTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
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
                  GlassContainer(
                     padding: const EdgeInsets.all(24),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          _buildTextField(
                            controller: _titleController,
                            hint: s.planTitleHint,
                            icon: Icons.auto_awesome_rounded,
                            isDark: isDark,
                            cs: cs,
                          ),
                          const SizedBox(height: 16),
                          _buildBudgetField(isDark: isDark, cs: cs, s: s),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _linksController,
                            hint: s.linksHint,
                            icon: Icons.link_rounded,
                            isDark: isDark,
                            cs: cs,
                          ),
                       ],
                     ),
                  ),
                  const SizedBox(height: 32),
                  SectionLabel(
                      label: s.planTypeLabel,
                      icon: Icons.category_rounded),
                  const SizedBox(height: 12),
                  _buildTypeSelector(isDark, cs),
                  const SizedBox(height: 32),
                  SectionLabel(label: "LIÊN KẾT NHÓM (TUỲ CHỌN)", icon: Icons.group_add_rounded),
                  const SizedBox(height: 12),
                  _buildGroupSelector(context, isDark, cs),
                  const SizedBox(height: 48),
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
                        child: Text(s.savePlan.toUpperCase(),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required ColorScheme cs,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
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

  Widget _buildBudgetField({required bool isDark, required ColorScheme cs, required AppStrings s}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1), width: 1.5),
      ),
      child: TextFormField(
        controller: _budgetController,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [CurrencyInputFormatter()],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cs.primary),
        decoration: InputDecoration(hintText: s.budgetHint, border: InputBorder.none),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark, ColorScheme cs) {
    return Wrap(
      spacing: 8,
      children: PlanType.values.map((type) {
        final isSelected = _selectedType == type;
        return FilterChip(
          label: Text(type.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          selected: isSelected,
          onSelected: (val) => setState(() => _selectedType = type),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          selectedColor: cs.primary.withValues(alpha: 0.2),
          checkmarkColor: cs.primary,
          labelStyle: TextStyle(color: isSelected ? cs.primary : (isDark ? Colors.white54 : Colors.black45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: isSelected ? cs.primary : Colors.white.withValues(alpha: 0.1)),
        );
      }).toList(),
    );
  }

  Widget _buildGroupSelector(BuildContext context, bool isDark, ColorScheme cs) {
    final groups = context.watch<AppState>().groups.where((g) => g.type == GroupType.planning).toList();
    if (groups.isEmpty) return const SizedBox();

    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedGroupId = null),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedGroupId == null ? cs.primary.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _selectedGroupId == null ? cs.primary : (isDark ? Colors.white24 : Colors.black12), width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_off_rounded, size: 22, color: _selectedGroupId == null ? cs.primary : (isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(width: 10),
                  const Text("Không\nliên kết", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, height: 1.1)),
                ],
              ),
            ),
          ),
          ...groups.map((g) {
            final isSelected = g.id == _selectedGroupId;
            return GestureDetector(
              onTap: () => setState(() => _selectedGroupId = g.id),
              child: Container(
                width: 170,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isSelected ? cs.primary : (isDark ? Colors.white24 : Colors.black12), width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.groups_rounded, size: 22, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(g.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    context.read<AppState>().updatePlan(widget.plan.copyWith(
      title: title,
      budgetTotal: double.tryParse(_budgetController.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
      referenceLinks: _linksController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      type: _selectedType,
      linkedGroupId: _selectedGroupId,
    ));
    Navigator.pop(context);
  }
}
