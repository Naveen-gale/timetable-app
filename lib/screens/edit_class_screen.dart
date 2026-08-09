import 'package:flutter/material.dart';

import '../models/timetable_entry.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/day_utils.dart';
import '../utils/time_utils.dart';
import '../widgets/custom_time_picker.dart';

/// Screen for editing an existing class or break entry.
class EditClassScreen extends StatefulWidget {
  final TimetableEntry entry;

  const EditClassScreen({super.key, required this.entry});

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  late TextEditingController _titleController;
  late TextEditingController _teacherController;
  late TextEditingController _roomController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _notificationEnabled;

  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e.title);
    _teacherController = TextEditingController(text: e.teacher);
    _roomController = TextEditingController(text: e.room);
    _startTime = TimeOfDay(hour: e.startHour, minute: e.startMinute);
    _endTime = TimeOfDay(hour: e.endHour, minute: e.endMinute);
    _notificationEnabled = e.notificationEnabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) {
      return widget.entry.isClass
          ? 'Subject is required.'
          : 'Break name is required.';
    }

    final start = TimeUtils.totalMinutes(_startTime);
    final end = TimeUtils.totalMinutes(_endTime);

    if (end <= start) return 'End time must be after start time.';

    // Check overlaps, excluding this entry.
    final existing = StorageService.instance.getEntriesForDay(widget.entry.day);
    for (final e in existing) {
      if (e.id == widget.entry.id) continue;
      if (TimeUtils.overlaps(
        startA: start,
        endA: end,
        startB: e.startTotalMinutes,
        endB: e.endTotalMinutes,
      )) {
        return 'This time overlaps with "${e.title}".';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final updated = widget.entry.copyWith(
      title: _titleController.text.trim(),
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      teacher: _teacherController.text.trim(),
      room: _roomController.text.trim(),
      notificationEnabled: _notificationEnabled,
    );

    await StorageService.instance.updateEntry(updated);

    // Cancel old, schedule new if applicable.
    await NotificationService.instance
        .cancelNotificationForEntry(updated.id);

    if (updated.isClass && _notificationEnabled) {
      final settings = StorageService.instance.getSettings();
      await NotificationService.instance.scheduleWeeklyClassNotification(
        entry: updated,
        minutesBefore: settings.notificationMinutesBefore,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isClass = widget.entry.isClass;

    return Scaffold(
      appBar: AppBar(
        title: Text(isClass ? 'Edit Class' : 'Edit Break'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionLabel(context, 'Day'),
          const SizedBox(height: 6),
          Text(DayUtils.fullName(widget.entry.day),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),

          _sectionLabel(context, isClass ? 'Subject *' : 'Break Name *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: isClass ? 'e.g. Mathematics' : 'e.g. Lunch Break',
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),

          _sectionLabel(context, 'Time *'),
          const SizedBox(height: 6),
          CustomTimePicker(
            label: 'Start Time',
            value: _startTime,
            onChanged: (t) => setState(() {
              _startTime = t;
              _error = null;
            }),
          ),
          const SizedBox(height: 12),
          CustomTimePicker(
            label: 'End Time',
            value: _endTime,
            onChanged: (t) => setState(() {
              _endTime = t;
              _error = null;
            }),
          ),

          if (isClass) ...[
            const SizedBox(height: 20),
            _sectionLabel(context, 'Optional'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _teacherController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Teacher Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room Number',
                prefixIcon: Icon(Icons.room_outlined),
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, 'Notification'),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              value: _notificationEnabled,
              onChanged: (v) => setState(() => _notificationEnabled = v),
              title: const Text('Notify before class'),
              contentPadding: EdgeInsets.zero,
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
