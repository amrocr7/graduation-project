import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prayer_model.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  static tz.TZDateTime _toTZ(DateTime dt) {
    final location = tz.getLocation('Asia/Riyadh');
    return tz.TZDateTime.from(dt, location);
  }

  static Future<void> schedulePrayerNotifications(List<PrayerTime> prayers) async {
    try {
      await _plugin.cancelAll();
      for (final prayer in prayers) {
        if (prayer.time.isAfter(DateTime.now())) {
          await _plugin.zonedSchedule(
            prayer.name.index,
            '${prayer.name.emoji} وقت ${prayer.name.arabic}',
            'الصلاة الآن — لا "بعدين"',
            _toTZ(prayer.time),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'prayer_channel',
                'مواقيت الصلاة',
                importance: Importance.max,
                priority: Priority.high,
                fullScreenIntent: true,
                ongoing: true,
                autoCancel: false,
                playSound: true,
              ),
            ),
            // inexact بدل exact — لا يحتاج إذن خاص
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) {
      // لو فشلت الإشعارات، التطبيق يكمل بدون crash
      print('Notification error: $e');
    }
  }

  static Future<void> scheduleLateNightWarning() async {
    try {
      final now = DateTime.now();
      var midnight = DateTime(now.year, now.month, now.day, 0, 30);
      if (midnight.isBefore(now)) {
        midnight = midnight.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        99,
        '⚠️ وقت خطر',
        'نام — البلايستيشن يكفي. الفجر قريب.',
        _toTZ(midnight),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'warning_channel',
            'تحذير الليل',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Warning notification error: $e');
    }
  }
}
