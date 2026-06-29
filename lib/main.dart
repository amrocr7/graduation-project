import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/prayer_calculator.dart';
import 'screens/lock_screen.dart';
import 'theme/app_theme.dart';

const String kDailyPrayerTask = 'daily_prayer_refresh';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kDailyPrayerTask) {
      final loc = await StorageService.getLocation();
      final lat = loc?['lat'] ?? 15.3694;
      final lng = loc?['lng'] ?? 44.1910;

      final prayers = PrayerCalculator(
        latitude: lat,
        longitude: lng,
        date: DateTime.now(),
      ).calculate();

      await NotificationService.schedulePrayerNotifications(prayers);
      await NotificationService.scheduleLateNightWarning();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  await NotificationService.init();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    kDailyPrayerTask,
    kDailyPrayerTask,
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 10),
    constraints: Constraints(networkType: NetworkType.not_required),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final loc = await StorageService.getLocation();
  final lat = loc?['lat'] ?? 15.3694;
  final lng = loc?['lng'] ?? 44.1910;

  final prayers = PrayerCalculator(
    latitude: lat,
    longitude: lng,
    date: DateTime.now(),
  ).calculate();

  await NotificationService.schedulePrayerNotifications(prayers);
  await NotificationService.scheduleLateNightWarning();

  runApp(const SalahApp());
}

class SalahApp extends StatelessWidget {
  const SalahApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'الكود',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const LockScreen(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
      );
}