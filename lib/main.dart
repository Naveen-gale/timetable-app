import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/app_settings.dart';
import 'models/timetable_entry.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive.
  await Hive.initFlutter();
  Hive.registerAdapter(EntryTypeAdapter());
  Hive.registerAdapter(TimetableEntryAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  await StorageService.instance.init();

  // Initialise notification service.
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  runApp(const TimetableApp());
}

class TimetableApp extends StatefulWidget {
  const TimetableApp({super.key});

  @override
  State<TimetableApp> createState() => _TimetableAppState();
}

class _TimetableAppState extends State<TimetableApp> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = StorageService.instance.getSettings();
  }

  void _onSettingsChanged() {
    setState(() {
      _settings = StorageService.instance.getSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTAPP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode(_settings.themeMode),
      home: _settings.isSetupComplete
          ? HomeScreen(onSettingsChanged: _onSettingsChanged)
          : SetupScreen(onSetupComplete: _onSettingsChanged),
    );
  }

  ThemeMode _themeMode(int mode) {
    switch (mode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
