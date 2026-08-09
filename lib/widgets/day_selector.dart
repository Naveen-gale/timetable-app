import 'package:flutter/material.dart';

import '../utils/day_utils.dart';

/// Horizontal scrollable pill-chip day selector.
class DaySelector extends StatelessWidget {
  final int selectedDay;
  final List<int> availableDays;
  final ValueChanged<int> onDaySelected;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.availableDays,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: DayUtils.allDays.map((day) {
          final isSelected = day == selectedDay;
          final isAvailable = availableDays.contains(day);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () => onDaySelected(day),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : isAvailable
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    DayUtils.shortName(day),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : isAvailable
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
