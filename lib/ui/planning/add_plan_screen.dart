import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../ui_helpers.dart';
import '../widgets/common_widgets.dart';
import 'plan_templates.dart';

class AddPlanScreen extends StatefulWidget {
  const AddPlanScreen({super.key});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _linksController = TextEditingController();
  final _destController = TextEditingController();
  PlanType _selectedType = PlanType.trip;
  String? _selectedGroupId;
  String? _selectedTemplateId;
  DateTime? _startDate;

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
          s.addPlanTitle,
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
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _destController,
                            hint: "Điểm đến (Thành phố, Quốc gia...)",
                            icon: Icons.location_on_rounded,
                            isDark: isDark,
                            cs: cs,
                          ),
                          const SizedBox(height: 16),
                          // Date Picker for Travel
                          _buildDateSelector(context, isDark, cs, s),
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
                  const SizedBox(height: 32),
                  SectionLabel(label: "SỬ DỤNG MẪU NHANH", icon: Icons.auto_awesome_rounded),
                  const SizedBox(height: 12),
                  _buildTemplateSelector(isDark, cs),
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
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 2)),
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
        decoration: InputDecoration(
          hintText: s.budgetHint,
          border: InputBorder.none,
          prefixIcon: Icon(Icons.bolt_rounded, color: cs.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, bool isDark, ColorScheme cs, AppStrings s) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _startDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (d != null) setState(() => _startDate = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _startDate == null ? "Chọn ngày bắt đầu" : DateFormat('dd/MM/yyyy').format(_startDate!),
                style: TextStyle(color: _startDate == null ? Colors.grey : (isDark ? Colors.white : Colors.black87)),
              ),
            ),
          ],
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
          label: Text(_getTypeName(type).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
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

  String _getTypeName(PlanType type) {
    switch (type) {
      case PlanType.trip: return "DU LỊCH";
      case PlanType.living: return "SINH HOẠT";
      case PlanType.event: return "SỰ KIỆN";
      case PlanType.other: return "KHÁC";
    }
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

  Widget _buildTemplateSelector(bool isDark, ColorScheme cs) {
    final templates = PlanTemplate.all;

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: templates.map((t) {
          final isSelected = _selectedTemplateId == t.id;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTemplateId = isSelected ? null : t.id;
                if (!isSelected) {
                   _titleController.text = t.name;
                   _selectedType = t.type;
                   _budgetController.text = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(t.budget).trim();
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? cs.primary.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? cs.primary : Colors.transparent, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(t.icon, size: 24, color: isSelected ? cs.primary : (isDark ? Colors.white38 : Colors.black38)),
                  const SizedBox(height: 8),
                  Text(t.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, height: 1.1), textAlign: TextAlign.center, maxLines: 2),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    List<PlanItineraryItem> itinerary = [];
    List<PlanTask> checklist = [];

    // -------------------------------------------------------------------------
    // TEMPLATE LOGIC EXPANSION
    // -------------------------------------------------------------------------
    if (_selectedTemplateId != null) {
      final template = PlanTemplate.all.firstWhere((t) => t.id == _selectedTemplateId);
      itinerary = template.itinerary;
      checklist = template.checklist;
    }

    context.read<AppState>().addPlan(BudgetPlan(
      title: title,
      type: _selectedType,
      budgetTotal: double.tryParse(_budgetController.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
      referenceLinks: _linksController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      status: PlanStatus.active,
      linkedGroupId: _selectedGroupId,
      itinerary: itinerary,
      checklist: checklist,
      destination: _destController.text.trim().isNotEmpty ? _destController.text.trim() : null,
      startDate: _startDate,
    ));
    Navigator.pop(context);
  }
}
