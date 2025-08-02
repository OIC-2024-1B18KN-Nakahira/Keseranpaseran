import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// バックグラウンドタスクのコールバック関数
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('WorkManagerタスク開始: $task');
      
      // バックグラウンドで通知を送信
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'workmanager_notification',
            'WorkManager Notifications',
            channelDescription: 'WorkManagerによる確実な通知',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'ケセランパセラン',
        'ケセランパセランにあった？待ってるよ！',
        platformChannelSpecifics,
      );

      print('WorkManager通知送信完了');
      return Future.value(true);
    } catch (e) {
      print('WorkManagerエラー: $e');
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WorkManagerの初期化
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false // 本番用にfalse
    );
    print('WorkManager初期化完了');
  } catch (e) {
    print('WorkManager初期化エラー: $e');
  }

  await Supabase.initialize(
    url: 'https://xcogckezaetipkwsnahp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjb2dja2V6YWV0aXBrd3NuYWhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5NDk3NDMsImV4cCI6MjA2NjUyNTc0M30.qAJktQrpAwGqVOZriaRwjWh-HKkCV2x8nUqso6w7LfA',
  );
  
  // アプリ起動時刻を記録
  await _recordAppOpen();

  runApp(ProviderScope(child: MyApp()));
}

Future<void> _recordAppOpen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_opened', DateTime.now().toIso8601String());
}

