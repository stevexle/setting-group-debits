import 'package:flutter/material.dart';
import '../../../l10n/strings.dart';
import 'dart:ui';

Future<void> showLiquidTimePicker(BuildContext context, {required TimeOfDay initialTime, required Function(TimeOfDay) onTimePicked}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cs = Theme.of(context).colorScheme;
  final s = AppStrings.of(context);
  
  int selectedHour = initialTime.hour;
  int selectedMinute = initialTime.minute;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, -10))],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10))),
                      Text(s.timeLabel.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 1.5)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 50,
                                perspective: 0.005,
                                diameterRatio: 1.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) => setModalState(() => selectedHour = index),
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 24,
                                  builder: (context, index) => Center(
                                    child: Text(index.toString().padLeft(2, '0'), 
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: selectedHour == index ? cs.primary : (isDark ? Colors.white24 : Colors.black12))),
                                  ),
                                ),
                              ),
                            ),
                            Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cs.primary)),
                            Expanded(
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 50,
                                perspective: 0.005,
                                diameterRatio: 1.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) => setModalState(() => selectedMinute = index),
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 60,
                                  builder: (context, index) => Center(
                                    child: Text(index.toString().padLeft(2, '0'), 
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: selectedMinute == index ? cs.primary : (isDark ? Colors.white24 : Colors.black12))),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            onTimePicked(TimeOfDay(hour: selectedHour, minute: selectedMinute));
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(s.save.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> showLiquidDatePicker(BuildContext context, {required DateTime initialDate, required Function(DateTime) onDatePicked}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    
    DateTime selectedDate = initialDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10))),
                  SizedBox(
                    height: 300,
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) => setModalState(() => selectedDate = date),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onDatePicked(selectedDate);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(s.save.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
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
