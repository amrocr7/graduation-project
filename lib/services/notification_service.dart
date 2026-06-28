import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prayer_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      _initialized = true;
    }
  }

  static tz.TZDateTime _toTZ(DateTime dt) {
    final location = tz.local;
    return tz.TZDateTime.from(dt, location);
  }

  static Future<void> schedulePrayerNotifications(List<PrayerTime> prayers) async {
    try {
      // لا نحذف كل شيء — نحذف فقط إشعارات الصلاة السابقة
      for (final p in prayers) {
        await _plugin.cancel(p.name.index);
      }

      for (final prayer in prayers) {
        final now = DateTime.now();
        if (prayer.time.isAfter(now)) {
          await _plugin.zonedSchedule(
            prayer.name.index,
            '${prayer.name.emoji} وقت ${prayer.name.arabic}',
            'الصلاة الآن — لا تأجيل',
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
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) {
      // لا نكسر التطبيق بسبب الإشعارات
      print('Notification error: $e');
    }
  }

  static Future<void> scheduleLateNightWarning() async {
    try {
      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, 0, 30);

      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }

      await _plugin.cancel(99);

      await _plugin.zonedSchedule(
        99,
        '⚠️ وقت راحة',
        'خفف استخدام الجوال، الفجر قريب',
        _toTZ(target),
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