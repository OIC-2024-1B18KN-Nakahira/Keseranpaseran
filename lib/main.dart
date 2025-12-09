import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'provider.dart';

/// ------------------------------
/// 🔔 WorkManager で実行されるバックグラウンド処理
/// ------------------------------
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

    // 通知の初期化（Android）
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

    // 通知内容
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'daily_channel',
      'Daily Notification',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    // 端末に通知を出す
    await notifications.show(
      0,
      'ケセランパセラン',
      randomMsg,
      notificationDetails,
    );

    return Future.value(true);
  });
}

/// ------------------------------
/// 🔥 FCM バックグラウンド
/// ------------------------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('バックグラウンド通知受信: ${message.messageId}');
}

/// ------------------------------
/// 🔥 main()
/// ------------------------------
Future<void> main() async {
  // Flutter Widgetバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数の読み込み
  await dotenv.load(fileName: '.env');

  // Supabaseの初期化
  await _initializeSupabase();

  // アプリ起動時刻の記録
  await _recordAppOpen();

  // -------------------------
  // 🔥 Workmanager 初期化
  // -------------------------
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // -------------------------
  // 🔥 毎日 12 時に通知を実行
  // -------------------------
  await Workmanager().registerPeriodicTask(
    "dailyNotification",
    "dailyNotificationTask",
    frequency: const Duration(days: 1),
    initialDelay: _calcInitialDelayForNoon(),
  );

  runApp(const ProviderScope(child: MainApp()));
}

/// 12:00 までの遅延時間を計算
Duration _calcInitialDelayForNoon() {
  final now = DateTime.now();
  DateTime nextNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);

  if (now.isAfter(nextNoon)) {
    nextNoon = nextNoon.add(const Duration(days: 1));
  }

  return nextNoon.difference(now);
}

/// ------------------------------
/// FCM 初期化
/// ------------------------------
Future<void> _initializeFCM() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();
  final token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  FirebaseMessaging.onMessage.listen((message) {
    print("フォアグラウンド通知受信: ${message.notification?.title}");
  });
}


/// Supabaseの初期化
Future<void> _initializeSupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || anonKey == null) {
    throw Exception(
      'Supabase credentials not found. '
      'Please check your .env file.',
    );
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

/// アプリ起動時刻の記録
Future<void> _recordAppOpen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_opened', DateTime.now().toIso8601String());
  } catch (e) {
    debugPrint('Failed to record app open time: $e');
  }
}

/// アプリケーションのルートWidget
class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  /// Deep Linkの処理
  void _handleDeepLinks() {
    // 認証状態の変化を監視
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('Auth event: $event');

      if (event == AuthChangeEvent.signedIn) {
        // ログイン成功時の処理
        debugPrint('User signed in');
      } else if (event == AuthChangeEvent.passwordRecovery) {
        // パスワードリセット時の処理
        debugPrint('Password recovery');
        // パスワード更新画面に遷移
        final router = ref.read(routerProvider);
        router.go('/password_update');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ケセランパセラン',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8EFF3C),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
    );
  }
}
