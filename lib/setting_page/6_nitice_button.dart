import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _isNotificationEnabled = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkNotificationPermission();
  }

  // 通知プラグインの初期化
  Future<void> _initializeNotifications() async {
    // タイムゾーンデータを初期化
    tz.initializeTimeZones();
    
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // 通知権限の現在の状態をチェック
  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _isNotificationEnabled = status.isGranted;
    });

    // 権限が許可されている場合、通知をスケジュール
    if (_isNotificationEnabled) {
      await _scheduleDailyNotification();
    }
  }

  // 通知権限を要求
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      setState(() {
        _isNotificationEnabled = true;
      });
      await _scheduleDailyNotification();
      _showPermissionDialog('通知権限が許可されました', '毎日ケセランパセランからの通知をお送りします。');
    } else if (status.isDenied) {
      setState(() {
        _isNotificationEnabled = false;
      });
      _showPermissionDialog('通知権限が拒否されました', '設定から手動で許可してください。');
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isNotificationEnabled = false;
      });
      _showSettingsDialog();
    }
  }

  // 毎日の通知をスケジュール（参考サイトに基づく実装）
  Future<void> _scheduleDailyNotification() async {
    // 既存の通知をキャンセル
    await flutterLocalNotificationsPlugin.cancelAll();
    await Workmanager().cancelAll();

    // Local Notifications版 - 毎日10時に通知
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'keseran_daily_channel',
          'ケセランパセラン毎日通知',
          channelDescription: '毎日のケセランパセランからのメッセージ',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // 毎日10時に通知を設定
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 10, 0, 0);
    
    // もし今日の10時がすでに過ぎていたら翌日に設定
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'ケセランパセラン',
      'ケセランパセランにあった？待ってるよ！',
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // WorkManager版 - バックグラウンドでも確実に動作
    await Workmanager().registerPeriodicTask(
      "keseran_daily_notification",
      "dailyNotificationTask",
      frequency: const Duration(hours: 24),
      initialDelay: Duration(
        milliseconds: scheduledDate.difference(now).inMilliseconds,
      ),
    );

    print('毎日10時の通知をスケジュールしました');
  }

  // 通知をキャンセル
  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    await Workmanager().cancelAll();
    print('すべての通知をキャンセルしました');
  }

  // 最後にアプリを開いた時間をチェック
  Future<String> _getLastOpenTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenedString = prefs.getString('last_opened');

    if (lastOpenedString != null) {
      final lastOpened = DateTime.parse(lastOpenedString);
      final timeDifference = DateTime.now().difference(lastOpened);

      if (timeDifference.inHours >= 24) {
        return '最後の起動から${timeDifference.inDays}日経過';
      } else {
        return '最後の起動から${timeDifference.inHours}時間経過';
      }
    }
    return '起動履歴なし';
  }

  // 権限ダイアログを表示
  void _showPermissionDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // 設定画面へのダイアログを表示
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('通知権限が必要です'),
          content: const Text('通知を受け取るには、設定アプリで通知権限を許可してください。\n\nまた、バッテリー最適化を「最適化しない」に設定することをお勧めします。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('設定を開く'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知設定')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '毎日の通知',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              'ケセランパセランからの毎日のメッセージ',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isNotificationEnabled,
                        onChanged: (value) async {
                          if (value) {
                            // オンにする場合は権限を要求
                            await _requestNotificationPermission();
                          } else {
                            // オフにする場合
                            await _cancelNotification();
                            setState(() {
                              _isNotificationEnabled = false;
                            });
                          }
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                  // 通知が有効な場合の追加UI
                  if (_isNotificationEnabled) ...[
                    const Divider(height: 32),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💝 毎日のメッセージ',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '「ケセランパセランにあった？待ってるよ！」',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '⏰ 毎日午前10時にお届け',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• アプリを閉じていても通知が届きます\n• WorkManagerとLocal Notificationの二重配信\n• バックグラウンドでも確実に動作',
                          style: TextStyle(fontSize: 12.0, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '⚠️ より確実に通知を受け取るために：',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• 端末設定でバッテリー最適化を「最適化しない」に設定\n• 通知設定で「サイレント配信」をオフに設定',
                          style: TextStyle(fontSize: 12.0, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<String>(
                      future: _getLastOpenTime(),
                      builder: (context, snapshot) {
                        return Text(
                          '⏰ ${snapshot.data ?? "読み込み中..."}',
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}