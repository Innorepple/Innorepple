import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // KYC
  Future<void> saveKyc(Map<String, dynamic> data) async {
    await _prefs.setString('kyc', jsonEncode(data));
    await _prefs.setBool('kyc_done', true);
  }

  Map<String, dynamic>? readKyc() {
    final s = _prefs.getString('kyc');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  // Medications
  Future<void> saveMeds(List<Map<String, dynamic>> meds) async {
    await _prefs.setString('meds', jsonEncode(meds));
  }

  List<Map<String, dynamic>> readMeds() {
    final s = _prefs.getString('meds');
    if (s == null) return [];
    final list = jsonDecode(s) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // Tips toggle
  bool get tipsEnabled => _prefs.getBool('tips_enabled') ?? true;
  Future<void> setTipsEnabled(bool v) => _prefs.setBool('tips_enabled', v);
  
  // Reminders toggle
  bool get remindersEnabled => _prefs.getBool('reminders_enabled') ?? true;
  Future<void> setRemindersEnabled(bool v) => _prefs.setBool('reminders_enabled', v);

  // Daily Checkup
  Future<void> saveDailyCheckup(String date, Map<String, dynamic> data) async {
    await _prefs.setString('daily_checkup_$date', jsonEncode(data));
  }

  Map<String, dynamic>? getDailyCheckup(String date) {
    final s = _prefs.getString('daily_checkup_$date');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  // Health metrics
  Future<void> saveHealthMetric(String key, double value) async {
    await _prefs.setDouble('health_$key', value);
  }

  double getHealthMetric(String key, double defaultValue) {
    return _prefs.getDouble('health_$key') ?? defaultValue;
  }
}
