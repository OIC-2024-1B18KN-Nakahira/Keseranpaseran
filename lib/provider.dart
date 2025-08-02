import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'realtime_service.dart';

final ageProvider = StateProvider<int>((ref) => 0);
final pregnantProvider = StateProvider<bool>((ref) => false);

// 認証状態を監視するProvider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// 現在のユーザーを取得するProvider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// 認証状態をboolで返すProvider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  final isAuth = user != null;

  // 認証状態の変化に応じてリアルタイム監視を制御
  if (isAuth) {
    RealtimeService.startListening();
  } else {
    RealtimeService.stopListening();
  }

  return isAuth;
});

// リアルタイムデータ更新の通知用Provider
final dataUpdateNotifierProvider = StateProvider<int>((ref) => 0);

// データ更新を通知する関数
void notifyDataUpdate(WidgetRef ref) {
  ref.read(dataUpdateNotifierProvider.notifier).state++;
}
