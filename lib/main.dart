import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_dotenv/flutter_dotenv.dart';
=======
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'provider.dart';

<<<<<<< HEAD
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
=======
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xcogckezaetipkwsnahp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjb2dja2V6YWV0aXBrd3NuYWhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5NDk3NDMsImV4cCI6MjA2NjUyNTc0M30.qAJktQrpAwGqVOZriaRwjWh-HKkCV2x8nUqso6w7LfA',
  );

  await _recordAppOpen();

>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

<<<<<<< HEAD
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
=======
Future<void> _recordAppOpen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_opened', DateTime.now().toIso8601String());
}

>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
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
