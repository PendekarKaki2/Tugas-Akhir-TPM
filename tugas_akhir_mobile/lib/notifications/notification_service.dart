import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  Future<void> showDailyReminderNow() async {
    if (kIsWeb) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'edufun_daily',
        'Daily Reminder',
        channelDescription: 'Pengingat belajar harian EduFun',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      101,
      'EduFun',
      'Ayo belajar hari ini!',
      details,
    );
  }
}
