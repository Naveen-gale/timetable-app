import 'package:hive/hive.dart';

part 'timetable_entry.g.dart';

/// Type of a timetable entry.
@HiveType(typeId: 0)
enum EntryType {
  @HiveField(0)
  classEntry,

  @HiveField(1)
  breakEntry,
}

/// A single timetable entry (class or break) for a specific weekday.
@HiveType(typeId: 1)
class TimetableEntry extends HiveObject {
  @HiveField(0)
  final String id;

  /// ISO weekday: 1 = Monday … 7 = Sunday
  @HiveField(1)
  final int day;

  @HiveField(2)
  final EntryType type;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final int startHour;

  @HiveField(5)
  final int startMinute;

  @HiveField(6)
  final int endHour;

  @HiveField(7)
  final int endMinute;

  /// Only used for class entries.
  @HiveField(8)
  final String teacher;

  /// Only used for class entries.
  @HiveField(9)
  final String room;

  @HiveField(10)
  final bool notificationEnabled;

  TimetableEntry({
    required this.id,
    required this.day,
    required this.type,
    required this.title,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.teacher = '',
    this.room = '',
    this.notificationEnabled = true,
  });

  /// Returns a new copy with the given fields overridden.
  TimetableEntry copyWith({
    String? id,
    int? day,
    EntryType? type,
    String? title,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? teacher,
    String? room,
    bool? notificationEnabled,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      day: day ?? this.day,
      type: type ?? this.type,
      title: title ?? this.title,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  /// Start time in total minutes from midnight — useful for sorting/comparing.
  int get startTotalMinutes => startHour * 60 + startMinute;

  /// End time in total minutes from midnight.
  int get endTotalMinutes => endHour * 60 + endMinute;

  bool get isClass => type == EntryType.classEntry;
  bool get isBreak => type == EntryType.breakEntry;

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'type': type.index,
        'title': title,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'teacher': teacher,
        'room': room,
        'notificationEnabled': notificationEnabled,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'] as String,
        day: json['day'] as int,
        type: EntryType.values[json['type'] as int],
        title: json['title'] as String,
        startHour: json['startHour'] as int,
        startMinute: json['startMinute'] as int,
        endHour: json['endHour'] as int,
        endMinute: json['endMinute'] as int,
        teacher: (json['teacher'] as String?) ?? '',
        room: (json['room'] as String?) ?? '',
        notificationEnabled: (json['notificationEnabled'] as bool?) ?? true,
      );
}
