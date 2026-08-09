import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../models/timetable_entry.dart';

/// Handles all local Hive storage operations.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _entriesBoxName = 'entries';
  static const String _settingsBoxName = 'settings';
  static const String _settingsKey = 'appSettings';

  late Box<TimetableEntry> _entriesBox;
  late Box<AppSettings> _settingsBox;

  /// Open Hive boxes. Must be called after [Hive.initFlutter].
  Future<void> init() async {
    _entriesBox = await Hive.openBox<TimetableEntry>(_entriesBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
  }

  // ──────────────────────────── Settings ────────────────────────────

  AppSettings getSettings() {
    return _settingsBox.get(_settingsKey) ?? AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(_settingsKey, settings);
  }

  // ──────────────────────────── Entries ─────────────────────────────

  List<TimetableEntry> getAllEntries() {
    return _entriesBox.values.toList();
  }

  List<TimetableEntry> getEntriesForDay(int day) {
    final entries = _entriesBox.values
        .where((e) => e.day == day)
        .toList()
      ..sort((a, b) => a.startTotalMinutes.compareTo(b.startTotalMinutes));
    return entries;
  }

  Future<void> addEntry(TimetableEntry entry) async {
    await _entriesBox.put(entry.id, entry);
  }

  Future<void> updateEntry(TimetableEntry entry) async {
    await _entriesBox.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _entriesBox.delete(id);
  }

  Future<void> clearAllEntries() async {
    await _entriesBox.clear();
  }

  // ──────────────────────────── Import / Export ──────────────────────

  Map<String, dynamic> exportAll() {
    final settings = getSettings();
    final entries = getAllEntries().map((e) => e.toJson()).toList();
    return {
      'settings': settings.toJson(),
      'entries': entries,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<String> exportAllAsJson() async {
    return jsonEncode(exportAll());
  }

  Future<void> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    if (data['settings'] != null) {
      final settings =
          AppSettings.fromJson(data['settings'] as Map<String, dynamic>);
      settings.isSetupComplete = true;
      await saveSettings(settings);
    }

    if (data['entries'] != null) {
      await clearAllEntries();
      final entries = (data['entries'] as List<dynamic>)
          .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final entry in entries) {
        await addEntry(entry);
      }
    }
  }
}
