import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keseranpaseran/provider.dart';
import 'package:keseranpaseran/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keseranpaseran/realtime_service.dart';

final supabase = Supabase.instance.client;

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayText = "${now.month}/${now.day}";

    return Stack(
      children: [
        Icon(
          Icons.calendar_today,
          size: 65,
          color: const Color.fromARGB(255, 50, 50, 50),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 28, left: 17),
          child: Text(todayText, style: TextStyle(fontSize: 17)),
        ),
      ],
    );
  }
}

class AppTitle extends ConsumerStatefulWidget {
  const AppTitle({super.key});

  @override
  ConsumerState<AppTitle> createState() => _AppTitleState();
}

class _AppTitleState extends ConsumerState<AppTitle> {
  int todayCaffeine = 0;
  String todaySleep = "0時間";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // リアルタイムコールバックを設定
    RealtimeService.setCaffeineCallback(_onDataChanged);
    RealtimeService.setSleepCallback(_onDataChanged);

    _loadTodayData();
  }

  // データ変更時のコールバック
  void _onDataChanged(Map<String, dynamic> payload) {
    print('AppTitle: データが変更されました');
    _loadTodayData(); // データを再読み込み
  }

  @override
  void dispose() {
    // コールバックをクリア
    RealtimeService.setCaffeineCallback((_) {});
    RealtimeService.setSleepCallback((_) {});
    super.dispose();
  }

  Future<void> _loadTodayData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 今日のカフェイン摂取量を取得
      final caffeineResponse = await supabase
          .from('caffeine_records')
          .select('amount_ml')
          .eq('user_id', user.id)
          .gte('recorded_at', '${todayString}T00:00:00.000Z')
          .lt(
            'recorded_at',
            '${DateTime(today.year, today.month, today.day + 1).toIso8601String().substring(0, 10)}T00:00:00.000Z',
          );

      int totalCaffeine = 0;
      for (final record in caffeineResponse) {
        final amountMl = record['amount_ml'] as int? ?? 0;
        totalCaffeine += (amountMl * 0.4).round();
      }

      // 今日の睡眠時間を取得（すべての記録を合計）
      final sleepResponse = await supabase
          .from('sleep_records')
          .select('sleep_duration_minutes')
          .eq('user_id', user.id)
          .eq('record_date', todayString);

      String sleepTime = "0時間";
      if (sleepResponse.isNotEmpty) {
        int totalSleepMinutes = 0;
        for (final record in sleepResponse) {
          final sleepMinutes = record['sleep_duration_minutes'] as int? ?? 0;
          totalSleepMinutes += sleepMinutes;
        }

        final hours = totalSleepMinutes ~/ 60;
        final minutes = totalSleepMinutes % 60;

        if (hours > 0 && minutes > 0) {
          sleepTime = "${hours}時間${minutes}分";
        } else if (hours > 0) {
          sleepTime = "${hours}時間";
        } else if (minutes > 0) {
          sleepTime = "${minutes}分";
        } else {
          sleepTime = "0時間";
        }
      }

      setState(() {
        todayCaffeine = totalCaffeine;
        todaySleep = sleepTime;
        isLoading = false;
      });

      // データ更新を通知
      notifyDataUpdate(ref);
    } catch (error) {
      print('データ取得エラー: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // データ更新通知を監視
    ref.watch(dataUpdateNotifierProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Text(
                      "カフェイン摂取量",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFFFA748), width: 5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        isLoading ? "読込中..." : "${todayCaffeine}mg/日",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Text(
                      "睡眠時間",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFFFA748), width: 5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: Text(
                      isLoading ? "読込中..." : "${todaySleep}/日",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
