// lib/services/daily_notification_service.dart

import 'dart:math';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ------------------------------
/// WorkManager のバックグラウンド処理
/// ------------------------------
void dailyNotificationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await notifications.initialize(initSettings);

    // ランダムメッセージ
    List<String> messages = [
      "今日もケセランパセランが応援してるよ！",
      "無理しすぎないで、少し休もうね！",
      "あなたの努力はちゃんと積み重なってるよ！",
      "今日はどんな一日？ 無理せずいこう！",
      "ケセランパセランがふわふわ見守ってるよ！"
    ];
    final randomMsg = messages[Random().nextInt(messages.length)];

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'daily_channel',
      'Daily Notification',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await notifications.show(
      0,
      'ケセランパセラン',
      randomMsg,
      details,
    );

    return Future.value(true);
  });
}

/// ------------------------------
/// 12:00 までの遅延時間を計算
/// ------------------------------
Duration calcInitialDelayForNoon() {
  final now = DateTime.now();
  var noon = DateTime(now.year, now.month, now.day, 12);

  if (now.isAfter(noon)) {
    noon = noon.add(const Duration(days: 1));
  }
  return noon.difference(now);
}

/// ------------------------------
/// Workmanager の初期化
/// ------------------------------
Future<void> setupDailyNotification() async {
  await Workmanager().initialize(
    dailyNotificationCallbackDispatcher,
    isInDebugMode: false,
  );

  await Workmanager().registerPeriodicTask(
    "dailyNotification",
    "dailyNotificationTask",
    frequency: const Duration(days: 1),
    initialDelay: calcInitialDelayForNoon(),
  );
}
