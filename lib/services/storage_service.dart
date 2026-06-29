import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';

class StorageService {
  static const _streakKey    = 'streak';
  static const _lastDateKey  = 'last_date';
  static const _recordsKey   = 'records';
  static const _latKey       = 'lat';
  static const _lngKey       = 'lng';
  static const _honorKey     = 'honor';
  static const _manualTimesKey = 'manual_times';
  static const _useManualKey   = 'use_manual';
  static const _dhikrKey       = 'dhikr';
  static const _passwordKey    = 'app_password';
  static const _biometricKey   = 'biometric_unlock';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ===== الموقع =====
  static Future<void> saveLocation(double lat, double lng) async {
    final p = await _prefs;
    await p.setDouble(_latKey, lat);
    await p.setDouble(_lngKey, lng);
  }
  static Future<Map<String, double>?> getLocation() async {
    final p = await _prefs;
    final lat = p.getDouble(_latKey);
    final lng = p.getDouble(_lngKey);
    if (lat == null || lng == null) return null;
    return {'lat': lat, 'lng': lng};
  }

  // ===== أوقات يدوية =====
  static Future<void> saveManualTimes(Map<PrayerName, String> times) async {
    final p = await _prefs;
    final map = times.map((k, v) => MapEntry(k.name, v));
    await p.setString(_manualTimesKey, jsonEncode(map));
  }
  static Future<Map<PrayerName, String>?> getManualTimes() async {
    final p = await _prefs;
    final raw = p.getString(_manualTimesKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(
      PrayerName.values.firstWhere((e) => e.name == k),
      v as String,
    ));
  }
  static Future<void> setUseManual(bool val) async {
    final p = await _prefs;
    await p.setBool(_useManualKey, val);
  }
  static Future<bool> getUseManual() async {
    final p = await _prefs;
    return p.getBool(_useManualKey) ?? false;
  }

  // ===== Streak =====
  static Future<int> getStreak() async {
    final p = await _prefs;
    return p.getInt(_streakKey) ?? 0;
  }
  static Future<void> checkAndUpdateStreak() async {
    final p     = await _prefs;
    final today = _todayStr();
    final last  = p.getString(_lastDateKey) ?? '';
    if (last == today) return;
    final record = await getTodayRecord();
    final yest   = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final streak = p.getInt(_streakKey) ?? 0;
    if (record.isPerfect) {
      await p.setInt(_streakKey, (last == yest || streak == 0) ? streak + 1 : 1);
    } else {
      await p.setInt(_streakKey, 0);
    }
    await p.setString(_lastDateKey, today);
  }

  // ===== سجل اليوم =====
  static Future<DayRecord> getTodayRecord() async {
    final p      = await _prefs;
    final today  = _todayStr();
    final records = _getMap(p);
    if (records.containsKey(today)) return DayRecord.fromJson(records[today]);
    return DayRecord(date: today, status: {for (var px in PrayerName.values) px: 'pending'});
  }
  static Future<void> savePrayerStatus(PrayerName prayer, String status) async {
    final p       = await _prefs;
    final today   = _todayStr();
    final records = _getMap(p);
    DayRecord rec;
    if (records.containsKey(today)) {
      rec = DayRecord.fromJson(records[today]);
    } else {
      rec = DayRecord(date: today, status: {for (var px in PrayerName.values) px: 'pending'});
    }
    rec.status[prayer] = status;
    records[today] = rec.toJson();
    await p.setString(_recordsKey, jsonEncode(records));
  }
  static Future<List<DayRecord>> getLastDays(int count) async {
    final p       = await _prefs;
    final records = _getMap(p);
    return List.generate(count, (i) {
      final date = _dateStr(DateTime.now().subtract(Duration(days: i)));
      if (records.containsKey(date)) return DayRecord.fromJson(records[date]);
      return DayRecord(date: date, status: {for (var px in PrayerName.values) px: 'pending'});
    });
  }

  // ===== الشرف =====
  static Future<HonorRecord> getHonor() async {
    final p = await _prefs;
    final raw = p.getString(_honorKey);
    if (raw == null) return HonorRecord();
    return HonorRecord.fromJson(jsonDecode(raw));
  }
  static Future<HonorRecord> updateHonor(int delta, String reason) async {
    final p      = await _prefs;
    final honor  = await getHonor();
    honor.points = (honor.points + delta).clamp(0, 1000);
    honor.history.insert(0, {
      'delta': delta,
      'reason': reason,
      'points': honor.points,
      'date': _todayStr(),
    });
    if (honor.history.length > 50) honor.history = honor.history.take(50).toList();
    await p.setString(_honorKey, jsonEncode(honor.toJson()));
    return honor;
  }

  // ===== عداد الذكر =====
  static Future<int> getDhikrCount() async {
    final p = await _prefs;
    final key = '${_dhikrKey}_${_todayStr()}';
    return p.getInt(key) ?? 0;
  }
  static Future<int> incrementDhikr() async {
    final p = await _prefs;
    final key = '${_dhikrKey}_${_todayStr()}';
    final val = (p.getInt(key) ?? 0) + 1;
    await p.setInt(key, val);
    return val;
  }
  static Future<void> resetDhikr() async {
    final p = await _prefs;
    final key = '${_dhikrKey}_${_todayStr()}';
    await p.setInt(key, 0);
  }

  // ===== قفل التطبيق =====
  static Future<bool> hasAppPassword() async {
    final p = await _prefs;
    return (p.getString(_passwordKey) ?? '').isNotEmpty;
  }
  static Future<String?> getAppPassword() async {
    final p = await _prefs;
    final val = p.getString(_passwordKey);
    return (val == null || val.isEmpty) ? null : val;
  }
  static Future<void> setAppPassword(String password) async {
    final p = await _prefs;
    if (password.trim().isEmpty) {
      await p.remove(_passwordKey);
      await p.setBool(_biometricKey, false);
    } else {
      await p.setString(_passwordKey, password.trim());
    }
  }
  static Future<bool> getBiometricUnlockEnabled() async {
    final p = await _prefs;
    return p.getBool(_biometricKey) ?? false;
  }
  static Future<void> setBiometricUnlockEnabled(bool value) async {
    final p = await _prefs;
    await p.setBool(_biometricKey, value);
  }

  // ===== تصدير / استيراد =====
  static Future<String> exportData() async {
    final p       = await _prefs;
    final records = _getMap(p);
    final honor   = await getHonor();
    final data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'streak': p.getInt(_streakKey) ?? 0,
      'records': records,
      'honor': honor.toJson(),
    };
    return jsonEncode(data);
  }
  static Future<bool> importData(String jsonStr) async {
    try {
      final p    = await _prefs;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['records'] != null) {
        await p.setString(_recordsKey, jsonEncode(data['records']));
      }
      if (data['streak'] != null) {
        await p.setInt(_streakKey, data['streak']);
      }
      if (data['honor'] != null) {
        await p.setString(_honorKey, jsonEncode(data['honor']));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> _getMap(SharedPreferences p) {
    final raw = p.getString(_recordsKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }
  static String _todayStr() => _dateStr(DateTime.now());
  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
