import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/timetable_entry.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/day_utils.dart';
import '../utils/time_utils.dart';
import '../widgets/custom_time_picker.dart';

/// Screen for adding a new class or break entry.
class AddClassScreen extends StatefulWidget {
  final int day;
  final bool isClass;

  const AddClassScreen({
    super.key,
    required this.day,
    required this.isClass,
  });

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _teacherController = TextEditingController();
  final _roomController = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _notificationEnabled = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.isClass) {
      _titleController.text = 'Break';
    }
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
      return widget.isClass ? 'Subject is required.' : 'Break name is required.';
    }
    if (_startTime == null) return 'Start time is required.';
    if (_endTime == null) return 'End time is required.';

    final start = TimeUtils.totalMinutes(_startTime!);
    final end = TimeUtils.totalMinutes(_endTime!);

    if (end <= start) return 'End time must be after start time.';

    // Check for overlaps.
    final existing = StorageService.instance.getEntriesForDay(widget.day);
    for (final e in existing) {
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

    final entry = TimetableEntry(
      id: const Uuid().v4(),
      day: widget.day,
      type: widget.isClass ? EntryType.classEntry : EntryType.breakEntry,
      title: _titleController.text.trim(),
      startHour: _startTime!.hour,
      startMinute: _startTime!.minute,
      endHour: _endTime!.hour,
      endMinute: _endTime!.minute,
      teacher: _teacherController.text.trim(),
      room: _roomController.text.trim(),
      notificationEnabled: _notificationEnabled,
    );

    await StorageService.instance.addEntry(entry);

    if (widget.isClass && _notificationEnabled) {
      final settings = StorageService.instance.getSettings();
      await NotificationService.instance.scheduleWeeklyClassNotification(
        entry: entry,
        minutesBefore: settings.notificationMinutesBefore,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isClass ? 'Add Class' : 'Add Break'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Day display
            _sectionLabel(context, 'Day'),
            const SizedBox(height: 6),
            Text(
              DayUtils.fullName(widget.day),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),

            // Title
            _sectionLabel(
                context, widget.isClass ? 'Subject *' : 'Break Name *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: widget.isClass ? 'e.g. Mathematics' : 'e.g. Lunch Break',
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 20),

            // Times
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

            if (widget.isClass) ...[
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
                title: const Text('Notify 5 minutes before'),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // Error
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
                child: const Text('Save'),
              ),
            ),
          ],
        ),
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
