import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/timetable_entry.dart';
import '../services/storage_service.dart';

/// Handles scheduling and cancelling of local notifications for timetable entries.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ──────────────────────────── Init ─────────────────────────────────

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Could navigate to the home screen – left for future enhancement.
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ──────────────────────────── Permissions ──────────────────────────

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) return false;

    final granted = await impl.requestNotificationsPermission();
    await impl.requestExactAlarmsPermission();
    return granted ?? false;
  }

  // ──────────────────────────── Schedule ─────────────────────────────

  /// Schedule a weekly recurring notification for a class entry.
  Future<void> scheduleWeeklyClassNotification({
    required TimetableEntry entry,
    required int minutesBefore,
  }) async {
    if (!_initialized) await initialize();
    if (!entry.isClass) return;

    final settings = StorageService.instance.getSettings();
    if (!settings.notificationsEnabled || !entry.notificationEnabled) return;

    // Cancel any existing notification for this entry first.
    await cancelNotificationForEntry(entry.id);

    final notifId = _notifIdFromEntryId(entry.id);

    // Compute the next occurrence of this weekday+time minus minutesBefore.
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = _nextWeekday(now, entry.day,
        entry.startHour, entry.startMinute, minutesBefore);

    const androidDetails = AndroidNotificationDetails(
      'timetable_class_channel',
      'Class Reminders',
      channelDescription: 'Notifications reminding you of upcoming classes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      notifId,
      'Upcoming Class',
      '${entry.title} starts in $minutesBefore minute${minutesBefore != 1 ? 's' : ''}.',
      scheduled,
      details,
      payload: entry.id,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    debugPrint(
        'Scheduled notification $notifId for "${entry.title}" at $scheduled');
  }

  /// Return the next [tz.TZDateTime] that matches [weekday] at ([hour]:[minute] - [minutesBefore]).
  tz.TZDateTime _nextWeekday(
    tz.TZDateTime from,
    int isoWeekday,
    int hour,
    int minute,
    int minutesBefore,
  ) {
    // Start with the exact class time today
    var candidate = tz.TZDateTime(
      tz.local,
      from.year,
      from.month,
      from.day,
      hour,
      minute,
    );

    // Advance until we hit the correct class day of the week
    while (candidate.weekday != isoWeekday) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // Subtract the reminder duration to get the actual notification time
    var notifTime = candidate.subtract(Duration(minutes: minutesBefore));

    // If the notification time has already passed today/this week, schedule for next week
    if (notifTime.isBefore(from)) {
      candidate = candidate.add(const Duration(days: 7));
      notifTime = candidate.subtract(Duration(minutes: minutesBefore));
    }

    return notifTime;
  }

  // ──────────────────────────── Cancel ───────────────────────────────

  Future<void> cancelNotificationForEntry(String entryId) async {
    await _plugin.cancel(_notifIdFromEntryId(entryId));
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ──────────────────────────── Reschedule ───────────────────────────

  Future<void> rescheduleAllNotifications() async {
    await cancelAllNotifications();
    final settings = StorageService.instance.getSettings();
    if (!settings.notificationsEnabled) return;

    final entries = StorageService.instance.getAllEntries();
    for (final entry in entries) {
      if (entry.isClass && entry.notificationEnabled) {
        await scheduleWeeklyClassNotification(
          entry: entry,
          minutesBefore: settings.notificationMinutesBefore,
        );
      }
    }
  }

  // ──────────────────────────── Test ─────────────────────────────────

  Future<void> sendTestNotification() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'timetable_class_channel',
      'Class Reminders',
      channelDescription: 'Notifications reminding you of upcoming classes',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(
      99999,
      'Test Notification',
      'Notifications are working correctly! 🎉',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ──────────────────────────── Helper ───────────────────────────────

  /// Convert a UUID entry ID to a stable integer notification ID.
  int _notifIdFromEntryId(String entryId) {
    return entryId.hashCode.abs() % 2147483647;
  }
}
