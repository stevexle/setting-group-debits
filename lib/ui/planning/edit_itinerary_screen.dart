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

class EditItineraryScreen extends StatefulWidget {
  final BudgetPlan plan;
  final PlanItineraryItem item;
  const EditItineraryScreen({super.key, required this.plan, required this.item});

  @override
  State<EditItineraryScreen> createState() => _EditItineraryScreenState();
}

class _EditItineraryScreenState extends State<EditItineraryScreen> {
  late TextEditingController activityController;
  late TextEditingController timeController;
  late TextEditingController locationController;
  late TextEditingController costController;
  late TextEditingController noteController;
  late TextEditingController mapLinkController;
  late TextEditingController referenceLinkController;
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
    activityController = TextEditingController(text: widget.item.activity);
    timeController = TextEditingController(text: widget.item.time);
    locationController = TextEditingController(text: widget.item.location ?? '');
    costController = TextEditingController(text: fmt.format(widget.item.estimatedCost).trim());
    noteController = TextEditingController(text: widget.item.note ?? '');
    mapLinkController = TextEditingController(text: widget.item.mapLink ?? '');
    referenceLinkController = TextEditingController(text: widget.item.socialLinks.isNotEmpty ? widget.item.socialLinks.first : '');
    selectedDay = widget.item.day;
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
          s.editItem,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
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
                   _buildDaySelector(context, s, isDark, cs),
                   const SizedBox(height: 24),
                   GlassContainer(
                     padding: const EdgeInsets.all(24),
                     child: Column(
                       children: [
                          _buildField(activityController, s.activityLabel, Icons.explore_rounded, isDark, cs),
                          const SizedBox(height: 16),
                          _buildField(
                            timeController, 
                            s.timeLabel, 
                            Icons.access_time_rounded, 
                            isDark, cs,
                            readOnly: true,
                            onTap: () async {
                               final parts = timeController.text.split(':');
                               final initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0);
                               await showLiquidTimePicker(
                                context,
                                initialTime: initial,
                                onTimePicked: (picked) {
                                  setState(() {
                                    timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildField(locationController, s.locationLabel, Icons.location_on_rounded, isDark, cs),
                          const SizedBox(height: 16),
                          _buildField(mapLinkController, s.googleMapsHint, Icons.map_rounded, isDark, cs),
                          const SizedBox(height: 16),
                          _buildField(referenceLinkController, "Link tham khảo (TikTok/FB/YT...)", Icons.link_rounded, isDark, cs),
                          const SizedBox(height: 16),
                          _buildField(noteController, s.notesHint, Icons.notes_rounded, isDark, cs),
                          const SizedBox(height: 16),
                          _buildField(costController, s.amountHint, Icons.bolt_rounded, isDark, cs, isNumber: true),
                       ],
                     ),
                   ),
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

  Widget _buildDaySelector(BuildContext context, AppStrings s, bool isDark, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.selectDay.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, index) {
              final day = index + 1;
              final isSelected = selectedDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text("D$day", style: const TextStyle(fontWeight: FontWeight.w900)),
                  selected: isSelected,
                  onSelected: (val) => setState(() => selectedDay = day),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              );
            },
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

  void _onSave() {
    final activity = activityController.text.trim();
    if (activity.isEmpty) return;
    context.read<AppState>().updateItineraryItem(
          widget.plan.id,
          widget.item.copyWith(
            activity: activity,
            day: selectedDay,
            location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
            time: timeController.text.trim().isEmpty ? '08:00' : timeController.text.trim(),
            estimatedCost: double.tryParse(costController.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
            mapLink: mapLinkController.text.trim().isEmpty ? null : mapLinkController.text.trim(),
            socialLinks: referenceLinkController.text.trim().isEmpty ? [] : [referenceLinkController.text.trim()],
          ),
        );
    Navigator.pop(context);
  }

  void _onDelete() {
     context.read<AppState>().removeItineraryItem(widget.plan.id, widget.item.id);
     Navigator.pop(context);
  }
}
