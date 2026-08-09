import 'package:flutter/material.dart';

/// Utilities for converting between integers and TimeOfDay,
/// and for formatting times as human-readable strings.
class TimeUtils {
  TimeUtils._();

  static TimeOfDay fromHourMinute(int hour, int minute) =>
      TimeOfDay(hour: hour, minute: minute);

  /// Format a TimeOfDay as "09:00 AM".
  static String format(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Format hour + minute integers as "09:00 AM".
  static String formatHM(int hour, int minute) =>
      format(TimeOfDay(hour: hour, minute: minute));

  /// Total minutes from midnight for comparison.
  static int totalMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Check whether two time ranges overlap (exclusive at the boundaries).
  static bool overlaps({
    required int startA,
    required int endA,
    required int startB,
    required int endB,
  }) {
    return startA < endB && startB < endA;
  }
}
