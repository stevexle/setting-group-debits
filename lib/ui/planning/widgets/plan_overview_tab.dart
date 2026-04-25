import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../widgets/common_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/external_data_service.dart';
import '../../ui_helpers.dart';

class PlanOverviewTab extends StatelessWidget {
  final BudgetPlan plan;
  final List<PersonalTransaction> txs;
  final NumberFormat fmt;
  final bool isDark;
  final AppStrings s;
  final Group? linkedGroup;
  final VoidCallback onEditPlan;
  final VoidCallback onDeletePlan;
  final VoidCallback onAddMember;

  const PlanOverviewTab({
    super.key, 
    required this.plan, 
    required this.txs, 
    required this.fmt, 
    required this.isDark, 
    required this.s, 
    this.linkedGroup,
    required this.onEditPlan, 
    required this.onDeletePlan,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    final targetBudget = plan.budgetTotal;
    
    // Calculate breakdowns
    final itineraryCost = plan.itinerary.fold<double>(0, (sum, item) => sum + item.estimatedCost);
    final checklistCost = plan.checklist.fold<double>(0, (sum, item) => sum + item.estimatedCost);
    final totalPlanned = itineraryCost + checklistCost;

    // Calculate task progress
    final totalTasks = plan.checklist.length;
    final completedTasks = plan.checklist.where((t) => t.status == PlanTaskStatus.done).length;
    final progress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.type == PlanType.trip) ...[
            _buildTravelDashboard(context),
            const SizedBox(height: 20),
          ],
          _buildContextActionCard(context),
          const SizedBox(height: 20),
          _buildAIPredictionCard(fmt, s, isDark),
          const SizedBox(height: 20),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.statusDone, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                    Text('$completedTasks / $totalTasks', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatCol(s.estimatedBudget, fmt.format(targetBudget), isDark ? Colors.white : Colors.black87, isDark),
                    const Spacer(),
                    _buildStatCol(s.totalPlanned, fmt.format(totalPlanned), totalPlanned > targetBudget ? Colors.redAccent : Colors.greenAccent, isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildAllocationCard(s.tabItinerary, fmt.format(itineraryCost), Icons.map_rounded, Colors.blueAccent, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildAllocationCard(s.tabChecklist, fmt.format(checklistCost), Icons.checklist_rounded, Colors.orangeAccent, isDark)),
            ],
          ),
          const SizedBox(height: 24),
          Text(s.referencesLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (plan.referenceLinks.isEmpty)
             Center(child: Text(s.noReferences, style: const TextStyle(color: Colors.grey, fontSize: 13)))
          else
            ...plan.referenceLinks.map((ref) => _buildReferenceCard(ref, isDark)),
          const SizedBox(height: 32),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onEditPlan(),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(s.editItem.toUpperCase()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onDeletePlan(),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: Text(s.deleteItem.toUpperCase()),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTravelDashboard(BuildContext context) {
    if (plan.destination == null) return const SizedBox();

    return FutureBuilder(
      future: Future.wait([
        ExternalDataService.getLiveWeather(plan.destination!),
        ExternalDataService.getExchangeRate(plan.destination!),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        final weather = snapshot.data?[0] as WeatherData?;
        final currencyMap = snapshot.data?[1] as Map<String, dynamic>?;
        
        final double? rate = currencyMap?['rate'];
        final String? symbol = currencyMap?['symbol'];
        
        final bool isDomestic = plan.destination != null && 
                                (plan.destination!.toLowerCase().contains("đà lạt") || 
                                 plan.destination!.toLowerCase().contains("vũng tàu") ||
                                 plan.destination!.toLowerCase().contains("nha trang") ||
                                 plan.destination!.toLowerCase().contains("việt nam") ||
                                 plan.destination!.toLowerCase().contains("hà nội") ||
                                 plan.destination!.toLowerCase().contains("hcm") ||
                                 plan.destination!.toLowerCase().contains("sài gòn") ||
                                 plan.destination!.toLowerCase().contains("phú quốc"));

        final now = DateTime.now();
        final bool hasStarted = plan.startDate != null && plan.startDate!.isBefore(now);
        final int daysUntil = plan.startDate != null ? UIHelpers.getDaysDifference(plan.startDate!) : -1;

        return Column(
          children: [
            if (plan.startDate != null && !hasStarted)
              _buildCountdownCard(daysUntil),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQuickWidget(
                  label: "${s.weatherLabel} @ ${plan.destination!.toUpperCase()}",
                  value: weather != null ? "${weather.temp.toInt()}°C" : (snapshot.connectionState == ConnectionState.waiting ? "..." : "--"),
                  subValue: weather?.condition ?? "...",
                  icon: Icons.wb_sunny_rounded,
                  color: Colors.orangeAccent,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickWidget(
                  label: isDomestic ? s.domesticLabel.toUpperCase() : s.currencyLabel.toUpperCase(),
                  value: isDomestic ? s.domesticLabel : (rate != null ? "${fmt.format(rate.toInt()).replaceAll('₫', '').trim()} đ/$symbol" : (snapshot.connectionState == ConnectionState.waiting ? "..." : "--")),
                  subValue: isDomestic ? "VNĐ" : s.currencySubLabel,
                  icon: isDomestic ? Icons.location_city_rounded : Icons.currency_exchange_rounded,
                  color: isDomestic ? Colors.purpleAccent : Colors.tealAccent,
                )),
              ],
            ),
          ],
        );
      }
    );
  }

  Widget _buildCountdownCard(int days) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.timer_rounded, color: Colors.orangeAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.startsInLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orangeAccent, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(s.daysRemainingLabel(days), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickWidget({required String label, required String value, required String subValue, required IconData icon, required Color color}) {
     return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            subValue,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAIPredictionCard(NumberFormat fmt, AppStrings s, bool isDark) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blueAccent.withValues(alpha: 0.1), Colors.purpleAccent.withValues(alpha: 0.1)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.orangeAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(s.aiPredictionHeader, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.orangeAccent, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    s.aiPredictionMessage(plan.itinerary.length),
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildStatCol(String label, String value, Color valColor, bool isDark) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 1),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

  Widget _buildAllocationCard(String label, String value, IconData icon, Color color, bool isDark) {
      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

  Widget _buildReferenceCard(String url, bool isDark) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, size: 16, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(url, 
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                onPressed: () => UIHelpers.openUrl(url),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildContextActionCard(BuildContext context) {
    if (plan.type == PlanType.trip) {
      // Find next activity
      PlanItineraryItem? nextItem;
      // Simple logic: first item for now
      if (plan.itinerary.isNotEmpty) nextItem = plan.itinerary.first;

      if (nextItem == null) return const SizedBox();

      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.near_me_rounded, color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rocket_launch_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(s.nextActivityLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(nextItem.activity, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      if (plan.startDate != null) ...[
                        Text(DateFormat('dd/MM').format(plan.startDate!.add(Duration(days: nextItem.day - 1))), 
                             style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        const Text(" • ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                      if (nextItem.location != null)
                         Expanded(child: Text(nextItem.location!, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            if (nextItem.mapLink != null)
              IconButton(
                icon: const Icon(Icons.directions_rounded),
                onPressed: () => UIHelpers.openUrl(nextItem!.mapLink),
              ),
          ],
        ),
      );
    } else if (plan.type == PlanType.living) {
       // Show quick category summary
       return GlassContainer(
         padding: const EdgeInsets.all(16),
         child: Row(
           children: [
             SizedBox(
               width: 60, height: 60,
               child: PieChart(PieChartData(
                 sections: [
                   PieChartSectionData(color: Colors.orangeAccent, value: 40, showTitle: false, radius: 10),
                   PieChartSectionData(color: Colors.blueAccent, value: 30, showTitle: false, radius: 10),
                   PieChartSectionData(color: Colors.greenAccent, value: 30, showTitle: false, radius: 10),
                 ],
                 centerSpaceRadius: 20,
                 sectionsSpace: 2,
               )),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text("TÌNH TRẠNG NGÂN SÁCH", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.orangeAccent, letterSpacing: 1.2)),
                   const SizedBox(height: 2),
                   const Text("Đang trong tầm kiểm soát", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                   Text("Bạn đã liệt kế được ${plan.checklist.length} khoản chi", style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                 ],
               ),
             ),
           ],
         ),
       );
    }
    return const SizedBox();
  }
}
