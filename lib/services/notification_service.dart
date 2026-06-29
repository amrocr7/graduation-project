import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prayer_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await requestNotificationPermission();
    _initialized = true;
  }

  static Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    final ios = await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    return ios ?? true;
  }

  static tz.TZDateTime _toTZ(DateTime dt) => tz.TZDateTime.from(dt, tz.local);

  static Future<void> schedulePrayerNotifications(List<PrayerTime> prayers) async {
    try {
      for (final p in prayers) { await _plugin.cancel(p.name.index); }
      for (final prayer in prayers) {
        if (prayer.time.isAfter(DateTime.now())) {
          await _plugin.zonedSchedule(
            prayer.name.index,
            '${prayer.name.emoji} وقت ${prayer.name.arabic}',
            'دخل وقت الصلاة الآن',
            _toTZ(prayer.time),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'prayer_channel',
                'مواقيت الصلاة',
                channelDescription: 'تنبيهات دخول وقت الصلاة بدون أذان وبصوت النظام',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                fullScreenIntent: false,
                ongoing: false,
                autoCancel: true,
              ),
              iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) { print('Notification error: $e'); }
  }

  static Future<void> scheduleLateNightWarning() async {
    try {
      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, 0, 30);
      if (target.isBefore(now)) target = target.add(const Duration(days: 1));
      await _plugin.cancel(99);
      await _plugin.zonedSchedule(
        99,
        '⚠️ وقت راحة',
        'خفف استخدام الجوال، الفجر قريب',
        _toTZ(target),
        const NotificationDetails(android: AndroidNotificationDetails('warning_channel', 'تحذير الليل', importance: Importance.high, priority: Priority.high, playSound: true)),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) { print('Warning notification error: $e'); }
  }
}
