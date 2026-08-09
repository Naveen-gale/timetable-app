import 'package:flutter/material.dart';

/// Shown when a day has no timetable entries.
class EmptyTimetable extends StatelessWidget {
  final VoidCallback onAddClass;

  const EmptyTimetable({super.key, required this.onAddClass});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 72,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'No classes scheduled',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first class.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAddClass,
              icon: const Icon(Icons.add),
              label: const Text('Add your first class'),
            ),
          ],
        ),
      ),
    );
  }
}
