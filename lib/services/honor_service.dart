import '../models/prayer_model.dart';
import 'storage_service.dart';
import 'sound_service.dart';

class HonorService {
  // نقاط التغيير
  static const int prayerOnTime  =  60;  // صلاة في وقتها
  static const int prayerQada    =  20;  // صلاة قضاء
  static const int prayerMissed  = -120; // صلاة فاتت
  static const int streakBonus   =  15;  // مكافأة يوم متتالي
  static const int perfectDay    =  30;  // يوم كامل مكافأة

  static Future<({HonorRecord honor, bool levelUp, bool levelDown})> onPrayerDone({
    required PrayerName prayer,
    required bool isOnTime,
    required int currentStreak,
  }) async {
    final delta = isOnTime ? prayerOnTime : prayerQada;
    final reason = isOnTime
        ? 'صليت ${prayer.arabic} في وقتها'
        : 'قضيت ${prayer.arabic}';
    return await _applyDelta(delta, reason);
  }

  static Future<({HonorRecord honor, bool levelUp, bool levelDown})> onPrayerMissed(
      PrayerName prayer) async {
    return await _applyDelta(prayerMissed, 'فاتتك ${prayer.arabic}');
  }

  static Future<({HonorRecord honor, bool levelUp, bool levelDown})> onStreakContinued(
      int streak) async {
    final bonus = streak >= 7 ? streakBonus * 2 : streakBonus;
    return await _applyDelta(bonus, 'استمريت $streak يوم');
  }

  static Future<({HonorRecord honor, bool levelUp, bool levelDown})> _applyDelta(
      int delta, String reason) async {
    final before = await StorageService.getHonor();
    final oldLevel = before.level;
    final honor = await StorageService.updateHonor(delta, reason);
    final newLevel = honor.level;

    final levelUp   = newLevel.index > oldLevel.index;
    final levelDown = newLevel.index < oldLevel.index;

    if (levelUp)   await SoundService.playHonorUp();
    if (levelDown) await SoundService.playHonorDown();

    return (honor: honor, levelUp: levelUp, levelDown: levelDown);
  }
}
