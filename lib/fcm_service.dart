// lib/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// FCM バックグラウンド
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("バックグラウンド通知: ${message.messageId}");
}

/// FCM 初期化
Future<void> initializeFCM() async {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission();

  final token = await FirebaseMessaging.instance.getToken();
  print("🔥 FCM TOKEN: $token");

  FirebaseMessaging.onMessage.listen((message) {
    print("フォアグラウンド通知: ${message.notification?.title}");
  });
}
