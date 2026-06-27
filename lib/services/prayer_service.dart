// lib/services/prayer_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';

/// حساب مواقيت الصلاة يدوياً بدون مكتبة خارجية
/// يستخدم خوارزمية أم القرى (السعودية / اليمن)
class PrayerCalculator {
  final double latitude;
  final double longitude;
  final DateTime date;

  PrayerCalculator({
    required this.latitude,
    required this.longitude,
    required this.date,
  });

  // حساب الجوليان ديت
  double _julianDate(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    double A = (year / 100).floorToDouble();
    double B = 2 - A + (A / 4).floorToDouble();
    return (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        day +
        B -
        1524.5;
  }

  double _calcTimeEq(double jd) {
    double D = jd - 2451545.0;
    double g = (357.529 + 0.98560028 * D) % 360;
    double q = (280.459 + 0.98564736 * D) % 360;
    double L = (q + 1.915 * _sin(g) + 0.020 * _sin(2 * g)) % 360;
    double R = 1.00014 - 0.01671 * _cos(g) - 0.00014 * _cos(2 * g);
    double e = 23.439 - 0.00000036 * D;
    double RA = _atan2(_cos(e) * _sin(L), _cos(L)) / 15;
    double eqT = q / 15 - _fixHour(RA);
    return eqT;
  }

  double _calcDeclination(double jd) {
    double D = jd - 2451545.0;
    double g = (357.529 + 0.98560028 * D) % 360;
    double q = (280.459 + 0.98564736 * D) % 360;
    double L = (q + 1.915 * _sin(g) + 0.020 * _sin(2 * g)) % 360;
    double e = 23.439 - 0.00000036 * D;
    return _asin(_sin(e) * _sin(L));
  }

  double _fixHour(double h) {
    h = h - 24 * (h / 24).floorToDouble();
    if (h < 0) h += 24;
    return h;
  }

  double _sin(double d) => _sinD(d);
  double _cos(double d) => _cosD(d);
  double _sinD(double d) => _mathSin(d * 3.14159265358979 / 180);
  double _cosD(double d) => _mathCos(d * 3.14159265358979 / 180);
  double _asin(double x) => _mathAsin(x) * 180 / 3.14159265358979;
  double _atan2(double y, double x) => _mathAtan2(y, x) * 180 / 3.14159265358979;

  double _mathSin(double x) {
    // Taylor series approximation
    double result = 0;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      result += term;
      term *= -x * x / ((2 * i) * (2 * i + 1));
    }
    return result;
  }

  double _mathCos(double x) {
    double result = 0;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      result += term;
      term *= -x * x / ((2 * i - 1) * (2 * i));
    }
    return result;
  }

  double _mathAsin(double x) {
    // Simple approximation
    return x + x * x * x / 6 + 3 * x * x * x * x * x / 40;
  }

  double _mathAtan2(double y, double x) {
    if (x > 0) return _mathAtan(y / x);
    if (x < 0 && y >= 0) return _mathAtan(y / x) + 3.14159265358979;
    if (x < 0 && y < 0) return _mathAtan(y / x) - 3.14159265358979;
    if (x == 0 && y > 0) return 3.14159265358979 / 2;
    if (x == 0 && y < 0) return -3.14159265358979 / 2;
    return 0;
  }

  double _mathAtan(double x) {
    return x - x * x * x / 3 + x * x * x * x * x / 5;
  }

  double _hourAngle(double angle, double decl) {
    double lat = latitude;
    double cosVal = (-_sinD(angle) - _sinD(lat) * _sinD(decl)) /
        (_cosD(lat) * _cosD(decl));
    if (cosVal < -1) cosVal = -1;
    if (cosVal > 1) cosVal = 1;
    return _mathAcos(cosVal) * 180 / 3.14159265358979;
  }

  double _mathAcos(double x) {
    return 3.14159265358979 / 2 - _mathAsin(x);
  }

  List<PrayerTime> calculate() {
    double jd = _julianDate(date.year, date.month, date.day);
    double eqT = _calcTimeEq(jd);
    double decl = _calcDeclination(jd);

    // Timezone offset
    double tz = longitude / 15;

    double transit = 12 + tz - longitude / 15 - eqT;

    // أوقات الصلاة بناء على زاوية الشمس (طريقة أم القرى)
    double fajrAngle = -19.0;    // أم القرى
    double ishaAngle = -19.0;    // أم القرى  
    double sunriseAngle = -0.833;
    double asrShadow = 1.0;      // شافعي

    double fajrHA   = _hourAngle(fajrAngle, decl);
    double sunriseHA = _hourAngle(sunriseAngle, decl);
    double asrAngle = -_asin(1 / (asrShadow + _mathTan((decl - latitude).abs() * 3.14159265358979 / 180)));
    double asrHA    = _hourAngle(asrAngle, decl);
    double maghribHA = _hourAngle(sunriseAngle, decl);
    double ishaHA   = _hourAngle(ishaAngle, decl);

    double fajrTime    = transit - fajrHA / 15;
    double dhuhrTime   = transit;
    double asrTime     = transit + asrHA / 15;
    double maghribTime = transit + maghribHA / 15;
    double ishaTime    = transit + ishaHA / 15;

    DateTime toDateTime(double hours) {
      int h = hours.floor();
      int m = ((hours - h) * 60).round();
      if (m == 60) { h++; m = 0; }
      return DateTime(date.year, date.month, date.day, h, m);
    }

    return [
      PrayerTime(name: PrayerName.fajr,    time: toDateTime(fajrTime)),
      PrayerTime(name: PrayerName.dhuhr,   time: toDateTime(dhuhrTime)),
      PrayerTime(name: PrayerName.asr,     time: toDateTime(asrTime)),
      PrayerTime(name: PrayerName.maghrib, time: toDateTime(maghribTime)),
      PrayerTime(name: PrayerName.isha,    time: toDateTime(ishaTime)),
    ];
  }

  double _mathTan(double x) => _mathSin(x) / _mathCos(x);
}

/// خدمة التخزين والسجل
class StorageService {
  static const _streakKey = 'streak';
  static const _lastDateKey = 'last_date';
  static const _recordsKey = 'records';
  static const _latKey = 'lat';
  static const _lngKey = 'lng';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // الموقع
  static Future<void> saveLocation(double lat, double lng) async {
    final prefs = await _prefs;
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lngKey, lng);
  }

  static Future<Map<String, double>?> getLocation() async {
    final prefs = await _prefs;
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    if (lat == null || lng == null) return null;
    return {'lat': lat, 'lng': lng};
  }

  // الـ Streak
  static Future<int> getStreak() async {
    final prefs = await _prefs;
    return prefs.getInt(_streakKey) ?? 0;
  }

  static Future<void> updateStreak(bool prayedAll) async {
    final prefs = await _prefs;
    final today = _todayStr();
    final lastDate = prefs.getString(_lastDateKey) ?? '';
    final streak = prefs.getInt(_streakKey) ?? 0;

    if (lastDate == today) return; // تم الحساب اليوم

    if (prayedAll) {
      final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate == yesterday || streak == 0) {
        await prefs.setInt(_streakKey, streak + 1);
      } else {
        // انكسر الـ streak
        await prefs.setInt(_streakKey, 1);
      }
    } else {
      await prefs.setInt(_streakKey, 0);
    }

    await prefs.setString(_lastDateKey, today);
  }

  // سجل الأيام
  static Future<DayRecord> getTodayRecord() async {
    final prefs = await _prefs;
    final today = _todayStr();
    final records = _getRecordsMap(prefs);

    if (records.containsKey(today)) {
      return DayRecord.fromJson(records[today]);
    }

    // يوم جديد
    return DayRecord(
      date: today,
      status: {for (var p in PrayerName.values) p: 'pending'},
    );
  }

  static Future<void> savePrayerStatus(
      PrayerName prayer, String status) async {
    final prefs = await _prefs;
    final today = _todayStr();
    final records = _getRecordsMap(prefs);

    DayRecord record;
    if (records.containsKey(today)) {
      record = DayRecord.fromJson(records[today]);
    } else {
      record = DayRecord(
        date: today,
        status: {for (var p in PrayerName.values) p: 'pending'},
      );
    }

    record.status[prayer] = status;
    records[today] = record.toJson();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  static Future<List<DayRecord>> getLastDays(int count) async {
    final prefs = await _prefs;
    final records = _getRecordsMap(prefs);
    final result = <DayRecord>[];

    for (int i = 0; i < count; i++) {
      final date = _dateStr(DateTime.now().subtract(Duration(days: i)));
      if (records.containsKey(date)) {
        result.add(DayRecord.fromJson(records[date]));
      } else {
        result.add(DayRecord(
          date: date,
          status: {for (var p in PrayerName.values) p: 'pending'},
        ));
      }
    }
    return result;
  }

  static Map<String, dynamic> _getRecordsMap(SharedPreferences prefs) {
    final raw = prefs.getString(_recordsKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static String _todayStr() => _dateStr(DateTime.now());
  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
