import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'provider.dart';

/// アプリケーションのエントリーポイント
Future<void> main() async {
  // Flutter Widgetバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数の読み込み
  await dotenv.load(fileName: '.env');

  // Supabaseの初期化
  await _initializeSupabase();

  // アプリ起動時刻の記録
  await _recordAppOpen();

  // アプリケーションの起動
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
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
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
