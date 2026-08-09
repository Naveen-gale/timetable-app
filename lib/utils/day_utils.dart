/// Utilities for working with days of the week.
class DayUtils {
  DayUtils._();

  /// Full day names indexed by ISO weekday (1=Monday … 7=Sunday).
  static const Map<int, String> fullNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  /// Short (3-letter) names.
  static const Map<int, String> shortNames = {
    1: 'MON',
    2: 'TUE',
    3: 'WED',
    4: 'THU',
    5: 'FRI',
    6: 'SAT',
    7: 'SUN',
  };

  static String fullName(int day) => fullNames[day] ?? 'Unknown';
  static String shortName(int day) => shortNames[day] ?? '???';

  /// All ISO weekday numbers.
  static const List<int> allDays = [1, 2, 3, 4, 5, 6, 7];

  /// Today's ISO weekday.
  static int today() => DateTime.now().weekday;
}
