import 'package:flutter/material.dart';
import 'router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xcogckezaetipkwsnahp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjb2dja2V6YWV0aXBrd3NuYWhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5NDk3NDMsImV4cCI6MjA2NjUyNTc0M30.qAJktQrpAwGqVOZriaRwjWh-HKkCV2x8nUqso6w7LfA',
  );
  // アプリ起動時刻を記録
  await _recordAppOpen();

  runApp(MyApp());
}
Future<void> _recordAppOpen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_opened', DateTime.now().toIso8601String());
 
}