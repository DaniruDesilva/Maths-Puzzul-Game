import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
    
    // Request permissions for Android 13+
    if (!kIsWeb) {
      _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }
  
  static Future<void> scheduleDailyReminder() async {
    // Cancel existing to avoid duplicates
    await _notificationsPlugin.cancelAll();
    
    // Schedule for 9:00 AM every day
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'number_haven_daily_challenge',
      'Number Haven Daily Challenge',
      channelDescription: 'Reminders to play the daily challenge to keep your streak',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
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
}
