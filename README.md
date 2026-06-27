# الكود — تطبيق المحافظة على الصلاة

## هيكل الملفات

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart
├── models/
│   └── prayer_model.dart
├── services/
│   ├── prayer_calculator.dart
│   ├── storage_service.dart
│   └── notification_service.dart
└── screens/
    ├── home_screen.dart
    ├── force_prayer_screen.dart
    ├── streak_screen.dart
    ├── stats_screen.dart
    └── code_screen.dart
```

## خطوات التشغيل

```bash
# 1. تثبيت الحزم
flutter pub get

# 2. تشغيل على أندرويد
flutter run

# 3. بناء APK
flutter build apk --release
```

## إعدادات Android المطلوبة

في `android/app/src/main/AndroidManifest.xml` أضف:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

## الميزات

- مواقيت الصلاة محسوبة محلياً (بدون نت) بطريقة أم القرى
- شاشة إجبار عند وقت الصلاة لا يمكن إغلاقها بسهولة
- تأجيل مرة واحدة فقط (15 دقيقة)
- نظام Streak يؤلم لو كسرته
- سجل صادق 30 يوم
- شاشة الكود الشخصي
- إشعار تحذير منتصف الليل

## لو أردت إضافة موقعك

في `storage_service.dart` غير القيم الافتراضية:
- latitude: 15.3694 (صنعاء)
- longitude: 44.1910

أو أضف شاشة إعدادات لاحقاً.
