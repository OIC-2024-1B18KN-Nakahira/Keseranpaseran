import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabaseの初期化を先に実行
  await Supabase.initialize(
    url: 'https://xcogckezaetipkwsnahp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjb2dja2V6YWV0aXBrd3NuYWhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5NDk3NDMsImV4cCI6MjA2NjUyNTc0M30.qAJktQrpAwGqVOZriaRwjWh-HKkCV2x8nUqso6w7LfA',
  );

  // アプリ起動時刻を記録
  await _recordAppOpen();

  runApp(ProviderScope(child: MainApp()));
}

Future<void> _recordAppOpen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_opened', DateTime.now().toIso8601String());
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ケセランパセラン',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
