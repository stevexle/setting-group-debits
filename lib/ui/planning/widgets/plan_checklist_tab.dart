import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../widgets/common_widgets.dart';
import '../../ui_helpers.dart';

class PlanChecklistTab extends StatelessWidget {
  final BudgetPlan plan;
  final NumberFormat fmt;
  final bool isDark;
  final AppStrings s;
  final Function(BuildContext, PlanTask, AppStrings) onToggleTask;
  final Function(PlanTask) onEdit;
  final Function(PlanTask) onAddSpend;

  const PlanChecklistTab({
    super.key, 
    required this.plan, 
    required this.fmt, 
    required this.isDark, 
    required this.s, 
    required this.onToggleTask, 
    required this.onEdit,
    required this.onAddSpend,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    Group? linkedGroup;
    if (plan.linkedGroupId != null) {
      final groups = state.groups.where((g) => g.id == plan.linkedGroupId);
      if (groups.isNotEmpty) linkedGroup = groups.first;
    }
    
    final checklist = plan.checklist;
    if (checklist.isEmpty) {
      return Center(
        child: EmptyCard(
          message: s.noTasksMsg,
          icon: Icons.checklist_rounded,
        ),
      );
    }

    // Sort checklist: Pending tasks first, then by priority (High -> Medium -> Low)
    final sortedTasks = List<PlanTask>.from(checklist)..sort((a, b) {
      if (a.status != b.status) {
        return a.status == PlanTaskStatus.done ? 1 : -1;
      }
      return b.priority.index.compareTo(a.priority.index);
    });

    final doneCount = checklist.where((t) => t.status == PlanTaskStatus.done).length;
    final totalCount = checklist.length;
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: sortedTasks.length + 1, // +1 for header
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(progress, doneCount, totalCount);
        final task = sortedTasks[index - 1];
        return _buildTaskCard(context, task, linkedGroup, fmt, isDark, s);
      },
    );
  }

  Widget _buildHeader(double progress, int done, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.budgetProgress.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text("$done / $total", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Colors.greenAccent, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.greenAccent : (isDark ? Colors.blueAccent : const Color(0xFF4A90E2))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, PlanTask task, Group? linkedGroup, NumberFormat fmt, bool isDark, AppStrings s) {
    final isDone = task.status == PlanTaskStatus.done;
    final color = UIHelpers.getPriorityColor(task.priority);
    Person? assignee;
    if (task.assignedTo != null && linkedGroup != null) {
      final people = linkedGroup.people.where((p) => p.id == task.assignedTo);
      if (people.isNotEmpty) assignee = people.first;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isDone ? 0.6 : 1.0,
        child: GestureDetector(
          onTap: () => onEdit(task),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => onToggleTask(context, task, s),
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone ? Colors.greenAccent : (isDark ? Colors.white24 : Colors.black12), 
                            width: 2
                          ),
                          color: isDone ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.transparent,
                        ),
                        child: isDone ? const Icon(Icons.check, size: 16, color: Colors.greenAccent) : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Category Icon
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(UIHelpers.getCategoryIcon(task.category), size: 10, color: isDark ? Colors.white54 : Colors.black54),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task.priority.name.toUpperCase(), 
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone 
                                ? (isDark ? Colors.white38 : Colors.black38) 
                                : (isDark ? Colors.white : const Color(0xFF1A1A2E))
                            )
                          ),
                          if (task.dueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.event_note_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(task.dueDate!),
                                    style: TextStyle(
                                      fontSize: 10, 
                                      color: isDark ? Colors.white60 : Colors.black54, 
                                      fontWeight: FontWeight.w600
                                    )
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (task.estimatedCost > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmt.format(task.estimatedCost),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: isDone 
                                ? (isDark ? Colors.white24 : Colors.black26) 
                                : (isDark ? Colors.orangeAccent : const Color(0xFFFF9F0A))
                            )
                          ),
                          const SizedBox(height: 4),
                          Material(
                             color: Colors.transparent,
                             child: InkWell(
                               onTap: () => onAddSpend(task), 
                               borderRadius: BorderRadius.circular(8),
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: Colors.orangeAccent.withValues(alpha: 0.1),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     const Icon(Icons.add_shopping_cart_rounded, size: 10, color: Colors.orangeAccent),
                                     const SizedBox(width: 4),
                                     Text(s.addSpendLabel, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.orangeAccent)),
                                   ],
                                 ),
                               ),
                             ),
                           ),
                        ],
                      ),
                  ],
                ),
                if (task.note != null && task.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 42),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        task.note!,
                        style: TextStyle(
                          fontSize: 11, 
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontStyle: FontStyle.italic
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (task.attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 42),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: task.attachments.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, idx) => Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                          ),
                          child: const Icon(Icons.insert_drive_file_rounded, size: 16, color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ),
                if (assignee != null || (task.contact != null && task.contact!.isNotEmpty)) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 0.5, color: Colors.white10),
                  ),
                  Row(
                    children: [
                      if (assignee != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.primaries[assignee.colorIndex % Colors.primaries.length].withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 8, 
                                backgroundColor: Colors.primaries[assignee.colorIndex % Colors.primaries.length], 
                                child: Text(assignee.name[0], style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))
                              ),
                              const SizedBox(width: 8),
                              Text(
                                assignee.name, 
                                style: TextStyle(
                                  fontSize: 11, 
                                  color: Colors.primaries[assignee.colorIndex % Colors.primaries.length], 
                                  fontWeight: FontWeight.w900
                                )
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      if (task.contact != null && task.contact!.isNotEmpty)
                        GestureDetector(
                          onTap: () => UIHelpers.makeCall(task.contact!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_in_talk_rounded, size: 14, color: Colors.greenAccent),
                                const SizedBox(width: 6),
                                Text(
                                  task.contact!, 
                                  style: const TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.w900)
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}
