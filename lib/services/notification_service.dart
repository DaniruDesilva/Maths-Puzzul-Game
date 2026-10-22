import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static const String channelId = 'number_haven_daily_challenge';
  static const String channelName = 'Number Haven Daily Challenge';
  static const String channelDescription = 'Reminders to play the daily challenge to keep your streak';

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    
    // Configure device local timezone accurately
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('Could not resolve device local timezone, fallback to local: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Register high-priority notification channel for Android 8.0+ (API 26+)
    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(channel);

      // Request runtime notification permission for Android 13+ (API 33+)
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  static Future<bool?> requestPermission() async {
    if (kIsWeb) return null;
    return await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
  
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Schedules daily 9:00 AM local reminder for the daily math challenge
  static Future<void> scheduleDailyReminder() async {
    // Cancel existing to avoid duplicate notifications
    await cancelAll();
    
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: 'New Daily Math Challenge! 🧠',
      body: 'Your new Number Haven daily puzzle is ready. Keep your streak alive!',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Sends an immediate test notification to confirm the system works
  static Future<void> showConfirmationNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: 999,
      title: 'Daily Reminders Active! 🔔',
      body: 'Your daily challenge reminder is set for 9:00 AM every morning.',
      notificationDetails: platformDetails,
    );
  }
}
