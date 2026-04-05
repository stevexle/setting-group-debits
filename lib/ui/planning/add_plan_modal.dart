import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../ui_helpers.dart';
import '../widgets/common_widgets.dart';

class AddPlanModal extends StatefulWidget {
  const AddPlanModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPlanModal(),
    );
  }

  @override
  State<AddPlanModal> createState() => _AddPlanModalState();
}

class _AddPlanModalState extends State<AddPlanModal> {
  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _linksController = TextEditingController();
  PlanType _selectedType = PlanType.trip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E2E).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -100,
                    child: AmbientGlow(
                        color: cs.primary, size: 250, opacity: 0.12),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16,
                        MediaQuery.of(context).viewInsets.bottom + 16),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                  color:
                                      isDark ? Colors.white24 : Colors.black12,
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          Text(
                            s.addPlanTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 24),
                          SectionLabel(
                              label: s.planTypeLabel,
                              icon: Icons.category_rounded),
                          const SizedBox(height: 12),
                          _buildTypeSelector(isDark, cs),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _onSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 8,
                                shadowColor: cs.primary.withValues(alpha: 0.3),
                              ),
                              child: Text(s.savePlan,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
          prefixIcon: Icon(icon, color: cs.primary, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildBudgetField(
      {required bool isDark, required ColorScheme cs, required AppStrings s}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        border:
            Border.all(color: cs.primary.withValues(alpha: 0.1), width: 1.5),
      ),
      child: TextFormField(
        controller: _budgetController,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [CurrencyInputFormatter()],
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: cs.primary,
        ),
        decoration: InputDecoration(
          hintText: s.budgetHint,
          border: InputBorder.none,
          prefixIcon: Icon(Icons.bolt_rounded, color: cs.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark, ColorScheme cs) {
    return Wrap(
      spacing: 8,
      children: PlanType.values.map((type) {
        final isSelected = _selectedType == type;
        return FilterChip(
          label: Text(type.name.toUpperCase(),
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          selected: isSelected,
          onSelected: (val) => setState(() => _selectedType = type),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          selectedColor: cs.primary.withValues(alpha: 0.2),
          checkmarkColor: cs.primary,
          labelStyle: TextStyle(
              color: isSelected
                  ? cs.primary
                  : (isDark ? Colors.white54 : Colors.black45)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(
              color: isSelected
                  ? cs.primary
                  : Colors.white.withValues(alpha: 0.1)),
        );
      }).toList(),
    );
  }

  void _onSave() {
    final title = _titleController.text.trim();
    final cleanBudget = _budgetController.text.replaceAll(RegExp(r'\D'), '');
    final budget = double.tryParse(cleanBudget) ?? 0.0;
    final links = _linksController.text
        .split(',')
        .where((s) => s.trim().startsWith('http'))
        .map((s) => s.trim())
        .toList();

    if (title.isEmpty) return;

    final plan = BudgetPlan(
      title: title,
      type: _selectedType,
      budgetTotal: budget,
      referenceLinks: links,
      status: PlanStatus.active,
    );

    context.read<AppState>().addPlan(plan);
    Navigator.pop(context);
  }
}
