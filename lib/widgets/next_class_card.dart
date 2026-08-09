import 'package:flutter/material.dart';

import '../models/timetable_entry.dart';
import '../utils/time_utils.dart';

/// Banner that shows the next upcoming class (or current class, or none).
class NextClassCard extends StatelessWidget {
  /// All entries for today sorted by start time.
  final List<TimetableEntry> todayEntries;

  const NextClassCard({super.key, required this.todayEntries});

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final nowMinutes = TimeUtils.totalMinutes(now);

    // Find the currently running class.
    final current = todayEntries.where((e) {
      if (!e.isClass) return false;
      return e.startTotalMinutes <= nowMinutes &&
          nowMinutes < e.endTotalMinutes;
    }).firstOrNull;

    // Find the next upcoming class.
    final next = todayEntries.where((e) {
      if (!e.isClass) return false;
      return e.startTotalMinutes > nowMinutes;
    }).firstOrNull;

    if (current == null && next == null) {
      return _noMoreClasses(context);
    }

    if (current != null) {
      return _classCard(context, current, isCurrent: true, minutesAway: null);
    }

    final minutesAway = next!.startTotalMinutes - nowMinutes;
    return _classCard(context, next, isCurrent: false, minutesAway: minutesAway);
  }

  Widget _noMoreClasses(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Text(
            'No more classes today',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _classCard(
    BuildContext context,
    TimetableEntry entry, {
    required bool isCurrent,
    required int? minutesAway,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrent
              ? [
                  colorScheme.tertiary.withValues(alpha: 0.8),
                  colorScheme.tertiary,
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.8),
                  colorScheme.primary,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCurrent ? 'CURRENT CLASS' : 'NEXT CLASS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${TimeUtils.formatHM(entry.startHour, entry.startMinute)} – ${TimeUtils.formatHM(entry.endHour, entry.endMinute)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          if (entry.room.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Room ${entry.room}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],
          if (!isCurrent && minutesAway != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                minutesAway < 60
                    ? 'Starts in $minutesAway minute${minutesAway != 1 ? 's' : ''}'
                    : 'Starts in ${minutesAway ~/ 60}h ${minutesAway % 60}m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
