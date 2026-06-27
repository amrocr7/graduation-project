enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

extension PrayerNameArabic on PrayerName {
  String get arabic {
    switch (this) {
      case PrayerName.fajr:    return 'الفجر';
      case PrayerName.dhuhr:   return 'الظهر';
      case PrayerName.asr:     return 'العصر';
      case PrayerName.maghrib: return 'المغرب';
      case PrayerName.isha:    return 'العشاء';
    }
  }
  String get emoji {
    switch (this) {
      case PrayerName.fajr:    return '🌙';
      case PrayerName.dhuhr:   return '☀️';
      case PrayerName.asr:     return '🌤️';
      case PrayerName.maghrib: return '🌅';
      case PrayerName.isha:    return '🌃';
    }
  }
}

class PrayerTime {
  final PrayerName name;
  final DateTime time;
  bool isDone;
  bool isMissed;
  PrayerTime({required this.name, required this.time, this.isDone = false, this.isMissed = false});
}

class DayRecord {
  final String date;
  final Map<PrayerName, String> status;
  DayRecord({required this.date, required this.status});
  int get doneCount   => status.values.where((s) => s == 'done').length;
  int get missedCount => status.values.where((s) => s == 'missed').length;
  bool get isPerfect  => doneCount == 5;

  Map<String, dynamic> toJson() => {
    'date': date,
    'status': status.map((k, v) => MapEntry(k.name, v)),
  };
  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
    date: json['date'],
    status: (json['status'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(PrayerName.values.firstWhere((e) => e.name == k), v as String),
    ),
  );
}

// ===== نموذج الشرف =====
enum HonorLevel {
  dishonorable, // ذليل 0-200
  sinner,       // عاصٍ 200-400
  repentant,    // تائب 400-550
  upright,      // مستقيم 550-700
  honorable,    // شريف 700-850
  legend,       // أسطورة 850-1000
}

extension HonorLevelInfo on HonorLevel {
  String get arabic {
    switch (this) {
      case HonorLevel.dishonorable: return 'ذليل';
      case HonorLevel.sinner:       return 'عاصٍ';
      case HonorLevel.repentant:    return 'تائب';
      case HonorLevel.upright:      return 'مستقيم';
      case HonorLevel.honorable:    return 'شريف';
      case HonorLevel.legend:       return 'أسطورة';
    }
  }
  int get minPoints {
    switch (this) {
      case HonorLevel.dishonorable: return 0;
      case HonorLevel.sinner:       return 200;
      case HonorLevel.repentant:    return 400;
      case HonorLevel.upright:      return 550;
      case HonorLevel.honorable:    return 700;
      case HonorLevel.legend:       return 850;
    }
  }
}

class HonorRecord {
  int points; // 0-1000, يبدأ من 500
  List<Map<String, dynamic>> history; // آخر تغييرات

  HonorRecord({this.points = 500, List<Map<String, dynamic>>? history})
      : history = history ?? [];

  HonorLevel get level {
    if (points >= 850) return HonorLevel.legend;
    if (points >= 700) return HonorLevel.honorable;
    if (points >= 550) return HonorLevel.upright;
    if (points >= 400) return HonorLevel.repentant;
    if (points >= 200) return HonorLevel.sinner;
    return HonorLevel.dishonorable;
  }

  double get percentage => points / 1000.0;

  // هل تغير المستوى بعد إضافة نقاط؟
  HonorLevel levelAfterChange(int delta) {
    final newPoints = (points + delta).clamp(0, 1000);
    if (newPoints >= 850) return HonorLevel.legend;
    if (newPoints >= 700) return HonorLevel.honorable;
    if (newPoints >= 550) return HonorLevel.upright;
    if (newPoints >= 400) return HonorLevel.repentant;
    if (newPoints >= 200) return HonorLevel.sinner;
    return HonorLevel.dishonorable;
  }

  Map<String, dynamic> toJson() => {
    'points': points,
    'history': history,
  };

  factory HonorRecord.fromJson(Map<String, dynamic> json) => HonorRecord(
    points: json['points'] ?? 500,
    history: List<Map<String, dynamic>>.from(json['history'] ?? []),
  );
}
