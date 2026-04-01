import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Request permissions
      final permissionGranted = await androidImpl?.requestNotificationsPermission();
      print('Notification permission granted: $permissionGranted');
      
      // Also request exact alarm permission for Android 12+
      try {
        await androidImpl?.requestExactAlarmsPermission();
      } catch (e) {
        print('Error requesting exact alarm permission: $e');
      }
    }
    // Timezone init
    try { 
      tz.initializeTimeZones(); 
    } catch (e) {
      print('Error initializing timezones: $e');
    }
  }

  Future<void> showNow({required String title, required String body}) async {
    const android = AndroidNotificationDetails('general', 'General', importance: Importance.max, priority: Priority.high);
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, const NotificationDetails(android: android));
  }

  Future<int> scheduleDaily({required String title, required String body, required TimeOfDay time}) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final android = const AndroidNotificationDetails('meds', 'Medication Reminders', importance: Importance.high, priority: Priority.high);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(time),
      NotificationDetails(android: android),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return id;
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  
  Future<void> scheduleMedication({required String medName, required String timeStr}) async {
    try {
      // Parse time string (assuming format like "09:00", "9:00", or "9:00 AM")
      String cleanTime = timeStr.trim();
      bool isPM = cleanTime.toLowerCase().contains('pm');
      bool isAM = cleanTime.toLowerCase().contains('am');
      
      // Remove AM/PM and other non-numeric characters except colon
      cleanTime = cleanTime.replaceAll(RegExp(r'[^0-9:]'), '');
      final timeParts = cleanTime.split(':');
      
      if (timeParts.length == 2) {
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        // Convert 12-hour to 24-hour format
        if (isPM && hour != 12) {
          hour += 12;
        } else if (isAM && hour == 12) {
          hour = 0;
        }
        
        // Ensure valid hour range
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          final time = TimeOfDay(hour: hour, minute: minute);
          print('Scheduling medication reminder for $medName at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
          
          await scheduleDaily(
            title: 'Medication Reminder 💊',
            body: 'Time to take your $medName',
            time: time,
          );
          print('Medication reminder scheduled successfully');
        } else {
          print('Invalid time values: hour=$hour, minute=$minute');
        }
      } else {
        print('Unable to parse time string: $timeStr');
      }
    } catch (e) {
      // Handle parsing errors gracefully
      print('Error scheduling medication reminder: $e');
    }
  }
}
