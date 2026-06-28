import 'dart:math';
import '../models/prayer_model.dart';

class PrayerCalculator {
  final double latitude;
  final double longitude;
  final DateTime date;

  PrayerCalculator({required this.latitude, required this.longitude, required this.date});

  double _rad(double d) => d * pi / 180;
  double _deg(double r) => r * 180 / pi;

  double _julianDay() {
    int y = date.year, m = date.month, d = date.day;
    if (m <= 2) { y--; m += 12; }
    double A = (y / 100).floorToDouble();
    double B = 2 - A + (A / 4).floorToDouble();
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() + d + B - 1524.5;
  }

  Map<String, double> _sunPosition() {
    double jd = _julianDay();
    double D  = jd - 2451545.0;
    double g  = _rad((357.529 + 0.98560028 * D) % 360);
    double q  = (280.459 + 0.98564736 * D) % 360;
    double L  = _rad((q + 1.915 * sin(g) + 0.020 * sin(2 * g)) % 360);
    double e  = _rad(23.439 - 0.00000036 * D);
    double RA = _deg(atan2(cos(e) * sin(L), cos(L))) / 15;
    double decl = _deg(asin(sin(e) * sin(L)));
    double eqT  = q / 15 - _fixHour(RA);
    return {'decl': decl, 'eqT': eqT};
  }

  double _fixHour(double h) {
    h = h % 24;
    return h < 0 ? h + 24 : h;
  }

  double _transit() {
    final sun = _sunPosition();
    return 12 - longitude / 15 - sun['eqT']!;
  }

  double _hourAngle(double angle, double decl) {
    double num = -sin(_rad(angle)) - sin(_rad(latitude)) * sin(_rad(decl));
    double den = cos(_rad(latitude)) * cos(_rad(decl));
    double val = num / den;
    val = val.clamp(-1.0, 1.0);
    return _deg(acos(val)) / 15;
  }

  double _asrAngle(double decl) {
    double angle = -_deg(atan(1 / (1 + tan(_rad((latitude - decl).abs())))));
    return _hourAngle(angle, decl);
  }

  double _toDateTime(double hours) {
    return hours;
  }

  List<PrayerTime> calculate() {
    final sun    = _sunPosition();
    final decl   = sun['decl']!;
    final transit = _transit();

    double fajrTime    = transit - _hourAngle(-19.0, decl);
    double dhuhrTime   = transit;
    double asrTime     = transit + _asrAngle(decl);
    double maghribTime = transit + _hourAngle(-0.833, decl);

    // إصلاح: العشاء حسب أم القرى = المغرب + 90 دقيقة
    double ishaTime = maghribTime + 1.5;

    return [
      PrayerTime(name: PrayerName.fajr,    time: DateTime(date.year, date.month, date.day, fajrTime.floor(), ((fajrTime % 1) * 60).round())),
      PrayerTime(name: PrayerName.dhuhr,   time: DateTime(date.year, date.month, date.day, dhuhrTime.floor(), ((dhuhrTime % 1) * 60).round())),
      PrayerTime(name: PrayerName.asr,     time: DateTime(date.year, date.month, date.day, asrTime.floor(), ((asrTime % 1) * 60).round())),
      PrayerTime(name: PrayerName.maghrib, time: DateTime(date.year, date.month, date.day, maghribTime.floor(), ((maghribTime % 1) * 60).round())),
      PrayerTime(name: PrayerName.isha,    time: DateTime(date.year, date.month, date.day, ishaTime.floor(), ((ishaTime % 1) * 60).round())),
    ];
  }
}