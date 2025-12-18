import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin = fln.FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    try {
        final currentTimeZone = await FlutterTimezone.getLocalTimezone();
        // The return type is TimezoneInfo, not String. Convert to string for parsing.
        String locationName = currentTimeZone.toString();
        
        // Simple heuristic: if it contains "Europe/Istanbul", force it.
        // Or if it contains "(", take the part before it? No, the log showed "TimezoneInfo(Europe/Istanbul..."
        
        if (locationName.contains('Europe/Istanbul')) {
          locationName = 'Europe/Istanbul';
        } 
        
        // Try to Load
        tz.setLocalLocation(tz.getLocation(locationName));
        print('DEBUG: Timezone loaded successfully: $locationName');
    } catch (e) {
        print('DEBUG: Could not get local timezone: $e');
        // Fallback to UTC if even Istanbul fails, or try Istanbul explicitly
        try {
           tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
           print('DEBUG: Fallback to Europe/Istanbul success');
        } catch (e2) {
           print('DEBUG: Fallback to Istanbul failed: $e2');
           tz.setLocalLocation(tz.UTC);
           print('DEBUG: Fallback to UTC');
        }
    }

    // Android settings
    const fln.AndroidInitializationSettings androidSettings =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final fln.DarwinInitializationSettings iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final fln.InitializationSettings settings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse response) {
        // Handle notification tap
      },
    );
    
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
       await _notificationsPlugin.resolvePlatformSpecificImplementation<
          fln.IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await _notificationsPlugin.cancel(0); // Cancel previous ID 0

    final scheduledTime = _nextInstanceOfTime(hour, minute);
    print('DEBUG: Scheduling reminder for $hour:$minute');
    print('DEBUG: Calculated Scheduled Time: $scheduledTime');

    if (Platform.isAndroid) {
      print('DEBUG: Attempting to schedule exact alarm on Android...');
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        0,
        'Egzersiz Zamanı! 💪',
        'Bugünkü hedeflerini tamamlamayı unutma.',
        scheduledTime,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'daily_reminder_channel_v3',
            'Günlük Hatırlatıcı',
            channelDescription: 'Günlük egzersiz hatırlatmaları',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
      print('DEBUG: Schedule successful');
    } catch (e) {
      print('DEBUG: Schedule failed error: $e');
    }
  }

  Future<void> showInstantNotification() async {
    const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
      'daily_reminder_channel_v2',
      'Günlük Hatırlatıcı',
      channelDescription: 'Günlük egzersiz hatırlatmaları',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const fln.NotificationDetails details = fln.NotificationDetails(
      android: androidDetails,
      iOS: fln.DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(
      1, // Different ID for test
      'Test Bildirimi 🔔',
      'Bu bir test bildirimidir. Hatırlatıcılarınız bu şekilde görünecek, içeriği ise motive edici olacak! 💪',
      details,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(0);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
