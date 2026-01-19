import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message.dart' as models;
import 'csv_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/message_detail_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static const String _keyStartDate = 'notification_start_date';
  static const String _keyCurrentDay = 'current_day_index';
  static GlobalKey<NavigatorState>? _navigatorKey;
  
  static const platform = MethodChannel('com.example.lijep_allahov_imena/alarm');

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    
    // Android postavke
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS postavke
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Zatraži dozvole
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print('Notification permission granted');
      }
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static void _onNotificationTapped(NotificationResponse response) async {
    print('Notifikacija pritisnuta: ${response.payload}');
    
    if (_navigatorKey?.currentContext != null) {
      final messages = await CsvService.loadMessages();
      if (messages.isEmpty) return;
      
      // Izračunaj trenutni dan na osnovu startnog datuma
      final dayIndex = await getCurrentDayIndex();
      final messageIndex = dayIndex % messages.length;
      final message = messages[messageIndex];
      
      _navigatorKey!.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MessageDetailScreen(message: message),
        ),
      );
    }
  }

  static Future<void> scheduleDailyNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await CsvService.loadMessages();

    if (messages.isEmpty) {
      print('Nema poruka za zakazivanje');
      return;
    }

    // Postavi datum početka ako ne postoji
    final startDate = prefs.getString(_keyStartDate);
    if (startDate == null) {
      await prefs.setString(_keyStartDate, DateTime.now().toIso8601String());
      await prefs.setInt(_keyCurrentDay, 0);
    }

    // Učitaj odabrano vrijeme iz postavki
    final hour = prefs.getInt('notification_hour') ?? 9;
    final minute = prefs.getInt('notification_minute') ?? 0;

    // Otkaži sve prethodne notifikacije
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('cancelAlarm');
      }
      await _notifications.cancelAll();
    } catch (e) {
      print('Greška pri otkazivanju notifikacija: $e');
    }

    // Zakaži dnevni alarm preko platform channela
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('scheduleDailyAlarm', {
          'hour': hour,
          'minute': minute,
        });
        print('Zakazan dnevni alarm za $hour:$minute');
      } else {
        // Za iOS koristi stari pristup
        await _scheduleDailyRepeatingNotification(hour, minute);
      }
    } catch (e) {
      print('Greška pri zakazivanju alarma: $e');
      // Fallback na stari pristup
      await _scheduleDailyRepeatingNotification(hour, minute);
    }

    // Sačuvaj poruke u SharedPreferences za kasniju upotrebu
    await _saveMessagesToPrefs(messages);

    print('Zakazana dnevna notifikacija');
  }

  static Future<void> _saveMessagesToPrefs(List<models.Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    // Sačuvaj broj poruka
    await prefs.setInt('total_messages', messages.length);
  }

  static Future<void> _scheduleDailyRepeatingNotification(int hour, int minute) async {
    // Kreiraj notifikaciju koja će se prikazati svaki dan
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Ako je već prošlo vrijeme, zakaži za sutra
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_messages',
      'Dnevne Poruke',
      channelDescription: 'Dnevne poruke sa Allahovim imenima',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Koristimo periodicallyShow umjesto zonedSchedule
    await _notifications.periodicallyShow(
      0, // Fixed ID za dnevnu notifikaciju
      'Allahovo ime',
      'Kliknite da vidite današnju poruku',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '0',
    );
  }

  static Future<void> showImmediateNotification(models.Message message) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_messages',
      'Dnevne Poruke',
      channelDescription: 'Dnevne poruke sa Allahovim imenima',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      message.id,
      'Allahovo ime',
      message.message,
      details,
      payload: message.id.toString(),
    );
  }

  static Future<void> testNativeNotification() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('testNotification');
        print('Native test notifikacija pozvana');
      }
    } catch (e) {
      print('Greška pri testiranju native notifikacije: $e');
    }
  }

  static Future<int> getCurrentDayIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final startDateStr = prefs.getString(_keyStartDate);
    
    if (startDateStr == null) {
      return 0;
    }

    final startDate = DateTime.parse(startDateStr);
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    
    return difference;
  }

  static Future<void> resetNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartDate);
    await prefs.remove(_keyCurrentDay);
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('cancelAlarm');
      }
      await _notifications.cancelAll();
    } catch (e) {
      print('Greška pri otkazivanju notifikacija: $e');
    }
    await scheduleDailyNotifications();
  }
}
