import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RealtimeService {
  static RealtimeChannel? _caffeineChannel;
  static RealtimeChannel? _sleepChannel;
  static RealtimeChannel? _userChannel;

  // 現在のユーザーIDを取得
  static String? get currentUserId => supabase.auth.currentUser?.id;

  // リアルタイム監視を開始
  static void startListening() {
    print('=== リアルタイム監視開始 ===');

    if (currentUserId == null) {
      print('ユーザーがログインしていません');
      return;
    }

    // カフェイン記録の監視
    _startCaffeineListening();

    // 睡眠記録の監視
    _startSleepListening();

    // ユーザー情報の監視
    _startUserListening();
  }

  // カフェイン記録の監視
  static void _startCaffeineListening() {
    _caffeineChannel = supabase.channel('caffeine-records-${currentUserId}');
    _caffeineChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'caffeine_records',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            print('=== カフェイン記録変更 ===');
            print('Event: ${payload.eventType}');
            print('Data: ${payload.newRecord}');

            // 変更をProviderに通知
            if (_onCaffeineChanged != null) {
              _onCaffeineChanged!({
                'eventType': payload.eventType.toString(),
                'new': payload.newRecord,
                'old': payload.oldRecord,
              });
            }
          },
        )
        .subscribe();
  }

  // 睡眠記録の監視
  static void _startSleepListening() {
    _sleepChannel = supabase.channel('sleep-records-${currentUserId}');
    _sleepChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sleep_records',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            print('=== 睡眠記録変更 ===');
            print('Event: ${payload.eventType}');
            print('Data: ${payload.newRecord}');

            // 変更をProviderに通知
            if (_onSleepChanged != null) {
              _onSleepChanged!({
                'eventType': payload.eventType.toString(),
                'new': payload.newRecord,
                'old': payload.oldRecord,
              });
            }
          },
        )
        .subscribe();
  }

  // ユーザー情報の監視
  static void _startUserListening() {
    _userChannel = supabase.channel('user-${currentUserId}');
    _userChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: currentUserId,
          ),
          callback: (payload) {
            print('=== ユーザー情報変更 ===');
            print('Event: ${payload.eventType}');
            print('Data: ${payload.newRecord}');

            // 変更をProviderに通知
            if (_onUserChanged != null) {
              _onUserChanged!({
                'eventType': payload.eventType.toString(),
                'new': payload.newRecord,
                'old': payload.oldRecord,
              });
            }
          },
        )
        .subscribe();
  }

  // 監視を停止
  static void stopListening() {
    print('=== リアルタイム監視停止 ===');

    _caffeineChannel?.unsubscribe();
    _sleepChannel?.unsubscribe();
    _userChannel?.unsubscribe();

    _caffeineChannel = null;
    _sleepChannel = null;
    _userChannel = null;

    _onCaffeineChanged = null;
    _onSleepChanged = null;
    _onUserChanged = null;
  }

  // コールバック関数
  static Function(Map<String, dynamic>)? _onCaffeineChanged;
  static Function(Map<String, dynamic>)? _onSleepChanged;
  static Function(Map<String, dynamic>)? _onUserChanged;

  // コールバック設定
  static void setCaffeineCallback(Function(Map<String, dynamic>) callback) {
    _onCaffeineChanged = callback;
  }

  static void setSleepCallback(Function(Map<String, dynamic>) callback) {
    _onSleepChanged = callback;
  }

  static void setUserCallback(Function(Map<String, dynamic>) callback) {
    _onUserChanged = callback;
  }
}
