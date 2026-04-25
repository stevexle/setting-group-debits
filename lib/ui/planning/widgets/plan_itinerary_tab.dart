import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../widgets/common_widgets.dart';
import '../../ui_helpers.dart';

class PlanItineraryTab extends StatelessWidget {
  final BudgetPlan plan;
  final NumberFormat fmt;
  final bool isDark;
  final AppStrings s;
  final Function(PlanItineraryItem) onEdit;
  final Function(PlanItineraryItem) onAddSpend;

  const PlanItineraryTab({
    super.key, 
    required this.plan, 
    required this.fmt, 
    required this.isDark, 
    required this.s, 
    required this.onEdit, 
    required this.onAddSpend
  });

  @override
  Widget build(BuildContext context) {
    final itinerary = plan.itinerary;
    if (itinerary.isEmpty) {
      return Center(
        child: EmptyCard(
          message: s.noItineraryMsg,
          icon: Icons.map_rounded,
        ),
      );
    }

    // Group items by day
    final Map<int, List<PlanItineraryItem>> grouped = {};
    for (var item in itinerary) {
      grouped.putIfAbsent(item.day, () => []).add(item);
    }
    final days = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final items = grouped[day]!..sort((a, b) => a.time.compareTo(b.time));
        final dayCost =
            items.fold<double>(0, (sum, item) => sum + item.estimatedCost);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDayHeader(day, dayCost, context),
            ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isLast = idx == items.length - 1;
                return _buildTimelineItem(item, isLast, fmt, isDark, s);
            }),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildDayHeader(int day, double dayCost, BuildContext context) {
    DateTime? actualDate;
    if (plan.startDate != null) {
      actualDate = plan.startDate!.add(Duration(days: day - 1));
    }

    final dateStr = actualDate != null ? DateFormat('EEEE, dd/MM', 'vi_VN').format(actualDate) : "Ngày $day";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1.2)),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                  children: [
                    TextSpan(text: actualDate != null ? "NGÀY $day" : s.tabItinerary.toUpperCase()),
                    if (actualDate != null) ...[
                      const TextSpan(text: " • ", style: TextStyle(color: Colors.blueAccent)),
                      TextSpan(text: DateFormat('dd/MM/yyyy').format(actualDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (dayCost > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(dayCost),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                Text(s.dailyEstimatedCost.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(PlanItineraryItem item, bool isLast, NumberFormat fmt, bool isDark, AppStrings s) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimelineIndicator(isLast),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onEdit(item),
                child: GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(item.time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                                    if (plan.startDate != null) ...[
                                      Text(" • ", style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.3))),
                                      Text(DateFormat('dd/MM').format(plan.startDate!.add(Duration(days: item.day - 1))), 
                                           style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent.withValues(alpha: 0.7))),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(item.activity, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                              ],
                            ),
                          ),
                          if (item.estimatedCost > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                              child: Text(fmt.format(item.estimatedCost), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                            ),
                        ],
                      ),
                      if (item.location != null || item.estimatedCost > 0 || item.mapLink != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (item.location != null) ...[
                              const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                              const SizedBox(width: 6),
                              Expanded(child: Text(item.location!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold))),
                            ],
                            const Spacer(),
                            if (item.estimatedCost > 0)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => onAddSpend(item),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.orangeAccent),
                                        const SizedBox(width: 6),
                                        Text(s.addSpendLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orangeAccent)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (item.mapLink != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.directions_rounded, color: Colors.blueAccent, size: 20),
                                onPressed: () => UIHelpers.openUrl(item.mapLink),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ]
                          ],
                        ),
                      ],
                      if (item.attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.attachments.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 60,
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                child: const Icon(Icons.insert_drive_file_rounded, size: 20, color: Colors.blueAccent),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
                          child: Text(item.note!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(bool isLast) {
    return SizedBox(
      width: 32,
      child: Column(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 4)],
            ),
          ),
          if (!isLast)
            Expanded(
              child: SizedBox(
                width: 2,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.2))),
              ),
            ),
        ],
      ),
    );
  }
}
