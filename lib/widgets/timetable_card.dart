import 'package:flutter/material.dart';

import '../models/timetable_entry.dart';
import '../utils/time_utils.dart';

/// Card widget for a class entry with swipe-to-reveal edit/delete actions.
class TimetableCard extends StatelessWidget {
  final TimetableEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TimetableCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key('class_${entry.id}'),
      background: _swipeBackground(
        context,
        Icons.edit_rounded,
        'Edit',
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
        AlignmentDirectional.centerStart,
      ),
      secondaryBackground: _swipeBackground(
        context,
        Icons.delete_rounded,
        'Delete',
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        AlignmentDirectional.centerEnd,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return _confirmDelete(context);
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimeUtils.formatHM(entry.startHour, entry.startMinute),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      TimeUtils.formatHM(entry.endHour, entry.endMinute),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Divider
                Container(
                  width: 2,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (entry.teacher.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(entry.teacher,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                      if (entry.room.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.room_outlined,
                                size: 14,
                                color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Room ${entry.room}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Notification badge
                if (entry.notificationEnabled)
                  Icon(Icons.notifications_active_outlined,
                      size: 16, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete this class?'),
            content:
                Text('Are you sure you want to delete "${entry.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _swipeBackground(
    BuildContext context,
    IconData icon,
    String label,
    Color bg,
    Color fg,
    AlignmentGeometry alignment,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
