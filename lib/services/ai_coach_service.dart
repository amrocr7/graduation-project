import '../models/prayer_model.dart';

class AiPrayerInsight {
  final String title;
  final String message;
  final PrayerName? focusPrayer;
  final double riskScore;
  final List<String> actions;

  const AiPrayerInsight({
    required this.title,
    required this.message,
    required this.focusPrayer,
    required this.riskScore,
    required this.actions,
  });

  bool get isHighRisk => riskScore >= 0.65;
}

class AiCoachService {
  const AiCoachService._();

  static AiPrayerInsight buildDailyInsight({
    required List<DayRecord> recentDays,
    required DayRecord today,
    required DateTime now,
    required PrayerTime? nextPrayer,
    required int streak,
  }) {
    final focusPrayer = _weakestPrayer(recentDays) ?? _nextPending(today, nextPrayer);
    final completionRate = _completionRate(recentDays);
    final todayDone = today.doneCount;
    final todayMissed = today.missedCount;
    final nextName = nextPrayer?.name.arabic;
    final risk = _riskScore(
      completionRate: completionRate,
      todayDone: todayDone,
      todayMissed: todayMissed,
      hour: now.hour,
      hasFocus: focusPrayer != null,
      streak: streak,
    );

    if (todayMissed > 0) {
      return AiPrayerInsight(
        title: 'خطة إنقاذ اليوم',
        message: 'الذكاء لاحظ صلاة فائتة اليوم. عالجها الآن، ثم اربط الصلاة القادمة ${nextName ?? ''} بتنبيه واضح قبلها بعشر دقائق.',
        focusPrayer: focusPrayer,
        riskScore: risk,
        actions: const ['اقضِ الفائتة فوراً', 'جهّز الوضوء قبل الأذان', 'لا تؤجل أكثر من مرة'],
      );
    }

    if (focusPrayer != null && completionRate < 0.8) {
      return AiPrayerInsight(
        title: 'تركيزك الذكي: ${focusPrayer.arabic}',
        message: 'تحليل آخر الأيام يقول إن ${focusPrayer.arabic} تحتاج حراسة أقوى. اجعلها هدف اليوم الأول ولا تنتظر آخر الوقت.',
        focusPrayer: focusPrayer,
        riskScore: risk,
        actions: ['منبّه قبل ${focusPrayer.arabic}', 'مكان ثابت للصلاة', 'مراجعة السجل مساءً'],
      );
    }

    if (streak >= 3) {
      return AiPrayerInsight(
        title: 'حافظ على الزخم',
        message: 'سلسلتك $streak أيام. أفضل قرار ذكي الآن هو حماية الصلاة القادمة ${nextName ?? 'في وقتها'} قبل أي انشغال.',
        focusPrayer: focusPrayer,
        riskScore: risk,
        actions: const ['صلِّ أول الوقت', 'لا تكسر السلسلة', 'اختم اليوم بمراجعة سريعة'],
      );
    }

    return AiPrayerInsight(
      title: 'مدربك الذكي جاهز',
      message: 'ابدأ اليوم بخطوة صغيرة: صلاة واحدة في أول وقتها ترفع الشرف وتبني سلسلة جديدة.',
      focusPrayer: focusPrayer,
      riskScore: risk,
      actions: const ['ابدأ بالصلاة القادمة', 'فعّل الإشعارات', 'سجّل بصدق'],
    );
  }

  static PrayerName? _weakestPrayer(List<DayRecord> days) {
    if (days.isEmpty) return null;
    PrayerName? weakest;
    var weakestRate = 1.1;
    for (final prayer in PrayerName.values) {
      final done = days.where((day) => day.status[prayer] == 'done').length;
      final rate = done / days.length;
      if (rate < weakestRate) {
        weakestRate = rate;
        weakest = prayer;
      }
    }
    return weakestRate < 0.9 ? weakest : null;
  }

  static PrayerName? _nextPending(DayRecord today, PrayerTime? nextPrayer) {
    if (nextPrayer != null && today.status[nextPrayer.name] != 'done') {
      return nextPrayer.name;
    }
    for (final prayer in PrayerName.values) {
      if (today.status[prayer] != 'done') return prayer;
    }
    return null;
  }

  static double _completionRate(List<DayRecord> days) {
    if (days.isEmpty) return 0;
    final done = days.fold<int>(0, (sum, day) => sum + day.doneCount);
    return done / (days.length * PrayerName.values.length);
  }

  static double _riskScore({
    required double completionRate,
    required int todayDone,
    required int todayMissed,
    required int hour,
    required bool hasFocus,
    required int streak,
  }) {
    var risk = 1 - completionRate;
    risk += todayMissed * 0.18;
    if (hour >= 20 && todayDone < 4) risk += 0.18;
    if (hasFocus) risk += 0.08;
    if (streak >= 3) risk -= 0.12;
    return risk.clamp(0.0, 1.0);
  }
}
