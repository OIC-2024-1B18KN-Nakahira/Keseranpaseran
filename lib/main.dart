import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'daily_notification_service.dart';
import 'fcm_service.dart';
import 'firebase_options.dart';

import 'provider.dart';



/// ------------------------------
/// 🔥 main()
/// ------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM 初期化
  await initializeFCM();

  // .env 読み込み
  await dotenv.load(fileName: '.env');

  // Supabase 初期化
  await _initializeSupabase();

  // アプリ起動時刻の記録
  await _recordAppOpen();

  // WorkManager（毎日通知）初期化
  await setupDailyNotification();

  runApp(const ProviderScope(child: MainApp()));
}

/// Supabase 初期化
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
