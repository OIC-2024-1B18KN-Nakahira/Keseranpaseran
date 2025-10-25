import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'realtime_service.dart';
import 'router.dart';

final ageProvider = StateProvider<int>((ref) => 0);

final pregnantProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  final isAuth = user != null;

  if (isAuth) {
    RealtimeService.startListening();
  } else {
    RealtimeService.stopListening();
  }

  return isAuth;
});

final dataUpdateNotifierProvider = StateProvider<int>((ref) => 0);

void notifyDataUpdate(WidgetRef ref) {
  ref.read(dataUpdateNotifierProvider.notifier).state++;
}

final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});
