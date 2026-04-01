import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization_service.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Settings keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyTipsEnabled = 'tips_enabled';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyReminderTime = 'reminder_time';
  static const String _keyAutoSync = 'auto_sync';
  static const String _keyLanguage = 'language';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyDataSaver = 'data_saver';
  static const String _keyPrivacyMode = 'privacy_mode';

  // Default values
  bool _notificationsEnabled = true;
  bool _tipsEnabled = true;
  bool _darkMode = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _autoSync = true;
  String _language = 'English';
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _dataSaver = false;
  bool _privacyMode = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get tipsEnabled => _tipsEnabled;
  bool get darkMode => _darkMode;
  TimeOfDay get reminderTime => _reminderTime;
  bool get autoSync => _autoSync;
  String get language => _language;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get dataSaver => _dataSaver;
  bool get privacyMode => _privacyMode;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    _notificationsEnabled = _prefs.getBool(_keyNotificationsEnabled) ?? true;
    _tipsEnabled = _prefs.getBool(_keyTipsEnabled) ?? true;
    _darkMode = _prefs.getBool(_keyDarkMode) ?? false;
    _autoSync = _prefs.getBool(_keyAutoSync) ?? true;
    _language = _prefs.getString(_keyLanguage) ?? 'English';
    _soundEnabled = _prefs.getBool(_keySoundEnabled) ?? true;
    _vibrationEnabled = _prefs.getBool(_keyVibrationEnabled) ?? true;
    _dataSaver = _prefs.getBool(_keyDataSaver) ?? false;
    _privacyMode = _prefs.getBool(_keyPrivacyMode) ?? false;

    // Load reminder time
    final hour = _prefs.getInt('${_keyReminderTime}_hour') ?? 9;
    final minute = _prefs.getInt('${_keyReminderTime}_minute') ?? 0;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
    
    // Load the saved language translations
    await LocalizationService.load(_language);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool(_keyNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setTipsEnabled(bool value) async {
    _tipsEnabled = value;
    await _prefs.setBool(_keyTipsEnabled, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    await _prefs.setInt('${_keyReminderTime}_hour', time.hour);
    await _prefs.setInt('${_keyReminderTime}_minute', time.minute);
    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _prefs.setBool(_keyAutoSync, value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _prefs.setString(_keyLanguage, value);
    // Load the new language translations
    await LocalizationService.load(value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool(_keySoundEnabled, value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _prefs.setBool(_keyVibrationEnabled, value);
    notifyListeners();
  }

  Future<void> setDataSaver(bool value) async {
    _dataSaver = value;
    await _prefs.setBool(_keyDataSaver, value);
    notifyListeners();
  }

  Future<void> setPrivacyMode(bool value) async {
    _privacyMode = value;
    await _prefs.setBool(_keyPrivacyMode, value);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    await _prefs.clear();
    _notificationsEnabled = true;
    _tipsEnabled = true;
    _darkMode = false;
    _reminderTime = const TimeOfDay(hour: 9, minute: 0);
    _autoSync = true;
    _language = 'English';
    _soundEnabled = true;
    _vibrationEnabled = true;
    _dataSaver = false;
    _privacyMode = false;
    notifyListeners();
  }

  // Get theme mode for the app
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  // Get formatted reminder time string
  String get reminderTimeString {
    final hour = _reminderTime.hour.toString().padLeft(2, '0');
    final minute = _reminderTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}