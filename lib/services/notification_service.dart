import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message.dart' as models;
import 'csv_service.dart';
import 'dart:io' show Platform;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../screens/message_detail_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static const String _keyStartDate = 'notification_start_date';
  static const String _keyCurrentDay = 'current_day_index';
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    
    // Inicijalizuj timezone
    tz.initializeTimeZones();
    // Postavi lokaciju na UTC+1 (Bosna i Hercegovina)
    tz.setLocalLocation(tz.getLocation('Europe/Sarajevo'));
    
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
    
    if (response.payload != null && _navigatorKey?.currentContext != null) {
      final messageId = int.tryParse(response.payload!);
      if (messageId != null) {
        final messages = await CsvService.loadMessages();
        final message = messages.firstWhere(
          (m) => m.id == messageId,
          orElse: () => messages.first,
        );
        
        _navigatorKey!.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(message: message),
          ),
        );
      }
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
    await _notifications.cancelAll();

    // Zakazi notifikacije za narednih 30 dana
    final now = DateTime.now();
    
    // Odredite prvi datum notifikacije
    DateTime firstNotificationDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // Ako je već prošlo odabrano vrijeme, počni od sutra
    if (now.hour > hour || (now.hour == hour && now.minute >= minute)) {
      firstNotificationDate = firstNotificationDate.add(const Duration(days: 1));
    }
    
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final scheduledDate = firstNotificationDate.add(Duration(days: i));

      await _scheduleNotification(
        id: message.id,
        title: 'Allahovo ime - Dan ${i + 1}',
        body: message.message,
        scheduledDate: scheduledDate,
        payload: message.id.toString(),
      );
    }

    print('Zakazano ${messages.length} notifikacija');
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
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

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: null,
      );
    } catch (e) {
      print('Greška pri zakazivanju notifikacije $id: $e');
      // Pokušaj sa jednostavnijim pristupom
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          _convertToTZDateTime(scheduledDate),
          details,
          androidScheduleMode: AndroidScheduleMode.exact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e2) {
        print('Greška pri drugom pokušaju zakazivanja notifikacije $id: $e2');
      }
    }
  }

  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    try {
      final location = tz.getLocation('Europe/Sarajevo');
      return tz.TZDateTime(
        location,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
      );
    } catch (e) {
      print('Greška pri konverziji timezone: $e');
      // Fallback na UTC ako ne uspe
      return tz.TZDateTime.utc(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
      );
    }
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
    await _notifications.cancelAll();
    await scheduleDailyNotifications();
  }
}
