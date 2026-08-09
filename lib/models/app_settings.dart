import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  /// ISO weekdays that the user has classes on (1=Mon … 7=Sun).
  @HiveField(0)
  List<int> selectedDays;

  /// 0 = system, 1 = light, 2 = dark
  @HiveField(1)
  int themeMode;

  @HiveField(2)
  bool notificationsEnabled;

  /// How many minutes before a class to fire the notification.
  @HiveField(3)
  int notificationMinutesBefore;

  @HiveField(4)
  bool isSetupComplete;

  AppSettings({
    List<int>? selectedDays,
    this.themeMode = 0,
    this.notificationsEnabled = true,
    this.notificationMinutesBefore = 5,
    this.isSetupComplete = false,
  }) : selectedDays = selectedDays ?? [1, 2, 3, 4, 5];

  Map<String, dynamic> toJson() => {
        'selectedDays': selectedDays,
        'themeMode': themeMode,
        'notificationsEnabled': notificationsEnabled,
        'notificationMinutesBefore': notificationMinutesBefore,
        'isSetupComplete': isSetupComplete,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        selectedDays: (json['selectedDays'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(),
        themeMode: (json['themeMode'] as int?) ?? 0,
        notificationsEnabled:
            (json['notificationsEnabled'] as bool?) ?? true,
        notificationMinutesBefore:
            (json['notificationMinutesBefore'] as int?) ?? 5,
        isSetupComplete: (json['isSetupComplete'] as bool?) ?? false,
      );
}
