import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/setup_screen.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/day_utils.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onChanged;

  const SettingsScreen({super.key, required this.onChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late var _settings = StorageService.instance.getSettings();

  Future<void> _saveSettings() async {
    await StorageService.instance.saveSettings(_settings);
    widget.onChanged();
  }

  // ─── Theme ────────────────────────────────────────────────────────

  Widget _themeSection(BuildContext context) {
    return _card(
      context,
      title: 'Appearance',
      icon: Icons.palette_outlined,
      children: [
        _settingTile(
          context,
          label: 'Theme',
          trailing: DropdownButton<int>(
            value: _settings.themeMode,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 0, child: Text('System')),
              DropdownMenuItem(value: 1, child: Text('Light')),
              DropdownMenuItem(value: 2, child: Text('Dark')),
            ],
            onChanged: (v) async {
              setState(() => _settings.themeMode = v ?? 0);
              await _saveSettings();
            },
          ),
        ),
      ],
    );
  }

  // ─── Days ─────────────────────────────────────────────────────────

  Widget _daysSection(BuildContext context) {
    return _card(
      context,
      title: 'Class Days',
      icon: Icons.calendar_month_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DayUtils.allDays.map((day) {
              final selected = _settings.selectedDays.contains(day);
              return FilterChip(
                label: Text(DayUtils.shortName(day)),
                selected: selected,
                onSelected: (v) async {
                  setState(() {
                    if (v) {
                      _settings.selectedDays.add(day);
                      _settings.selectedDays.sort();
                    } else {
                      _settings.selectedDays.remove(day);
                    }
                  });
                  await _saveSettings();
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Notifications ────────────────────────────────────────────────

  Widget _notifSection(BuildContext context) {
    return _card(
      context,
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      children: [
        SwitchListTile.adaptive(
          title: const Text('Enable Notifications'),
          value: _settings.notificationsEnabled,
          onChanged: (v) async {
            setState(() => _settings.notificationsEnabled = v);
            await _saveSettings();
            if (v) {
              await NotificationService.instance.rescheduleAllNotifications();
            } else {
              await NotificationService.instance.cancelAllNotifications();
            }
          },
        ),
        _settingTile(
          context,
          label: 'Notify before class',
          trailing: DropdownButton<int>(
            value: _settings.notificationMinutesBefore,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 minutes')),
              DropdownMenuItem(value: 10, child: Text('10 minutes')),
              DropdownMenuItem(value: 15, child: Text('15 minutes')),
              DropdownMenuItem(value: 30, child: Text('30 minutes')),
            ],
            onChanged: (v) async {
              setState(
                  () => _settings.notificationMinutesBefore = v ?? 5);
              await _saveSettings();
              await NotificationService.instance
                  .rescheduleAllNotifications();
            },
          ),
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          leading: const Icon(Icons.send_rounded),
          title: const Text('Send Test Notification'),
          onTap: () async {
            final granted =
                await NotificationService.instance.requestPermissions();
            if (!granted) {
              _showSnack('Notification permission denied.');
              return;
            }
            await NotificationService.instance.sendTestNotification();
            _showSnack('Test notification sent!');
          },
        ),
        ListTile(
          leading: const Icon(Icons.refresh_rounded),
          title: const Text('Reschedule All Notifications'),
          onTap: () async {
            await NotificationService.instance
                .rescheduleAllNotifications();
            _showSnack('All notifications rescheduled.');
          },
        ),
        ListTile(
          leading: Icon(Icons.notifications_off_outlined,
              color: Theme.of(context).colorScheme.error),
          title: Text(
            'Cancel All Notifications',
            style: TextStyle(
                color: Theme.of(context).colorScheme.error),
          ),
          onTap: () async {
            await NotificationService.instance.cancelAllNotifications();
            _showSnack('All notifications cancelled.');
          },
        ),
      ],
    );
  }

  // ─── Data ─────────────────────────────────────────────────────────

  Widget _dataSection(BuildContext context) {
    return _card(
      context,
      title: 'Data',
      icon: Icons.folder_outlined,
      children: [
        ListTile(
          leading: const Icon(Icons.upload_rounded),
          title: const Text('Export Timetable'),
          subtitle: const Text('Save as JSON file'),
          onTap: _exportData,
        ),
        ListTile(
          leading: const Icon(Icons.download_rounded),
          title: const Text('Import Timetable'),
          subtitle: const Text('Restore from JSON file'),
          onTap: _importData,
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          leading: Icon(Icons.delete_forever_rounded,
              color: Theme.of(context).colorScheme.error),
          title: Text(
            'Clear All Data',
            style: TextStyle(
                color: Theme.of(context).colorScheme.error),
          ),
          onTap: _clearData,
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    try {
      final json = await StorageService.instance.exportAllAsJson();
      final dir = await _tmpDir();
      final file = File('$dir/timetable_export.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My TimeTable export',
      );
    } catch (e) {
      _showSnack('Export failed: $e');
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;
      final content = await File(path).readAsString();
      await StorageService.instance.importFromJson(content);
      await NotificationService.instance.rescheduleAllNotifications();
      setState(() => _settings = StorageService.instance.getSettings());
      widget.onChanged();
      _showSnack('Timetable imported successfully.');
    } catch (e) {
      _showSnack('Import failed: $e');
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This will delete all timetable entries. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.instance.cancelAllNotifications();
      await StorageService.instance.clearAllEntries();
      widget.onChanged();
      _showSnack('All data cleared.');
    }
  }

  Future<String> _tmpDir() async {
    final dir = Directory.systemTemp;
    return dir.path;
  }

  // ─── About ────────────────────────────────────────────────────────

  Widget _aboutSection(BuildContext context) {
    return _card(
      context,
      title: 'About',
      icon: Icons.info_outlined,
      children: [
        const ListTile(
          title: Text('App Name'),
          trailing: Text('TTAPP'),
        ),
        const ListTile(
          title: Text('Version'),
          trailing: Text('1.0.0'),
        ),
        const ListTile(
          title: Text('Developer'),
          trailing: Text('Naveen'),
        ),
      ],
    );
  }

  // ─── Re-run setup ─────────────────────────────────────────────────

  Widget _setupSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () async {
          final navigator = Navigator.of(context);
          final settings = StorageService.instance.getSettings();
          settings.isSetupComplete = false;
          await StorageService.instance.saveSettings(settings);
          if (!mounted) return;
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => SetupScreen(
                onSetupComplete: () {
                  widget.onChanged();
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.tune_rounded),
        label: const Text('Re-run Day Setup'),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _themeSection(context),
          _daysSection(context),
          _notifSection(context),
          _dataSection(context),
          _aboutSection(context),
          const SizedBox(height: 16),
          _setupSection(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
