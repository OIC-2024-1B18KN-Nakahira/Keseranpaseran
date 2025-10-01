import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keseranpaseran/provider.dart';
import 'package:keseranpaseran/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayText = "${now.month}/${now.day}";

    return Stack(
      children: [
        const Icon(
          Icons.calendar_today,
          size: 50,
          color: Color.fromARGB(255, 50, 50, 50),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, left: 10),
          child: Text(todayText, style: TextStyle(fontSize: 15)),
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

  // カフェイン計算関数を追加（home.dartと同じ）
  double calculateCaffeineFromRecord(String drinkType, int amountMl) {
    switch (drinkType) {
      case "コーラ":
        return (amountMl / 350.0) * 40.0;
      case "コーヒー":
      case "紅茶":
        return (amountMl / 200.0) * 60.0;
      case "栄養ドリンク":
      case "エナジードリンク":
        return (amountMl / 100.0) * 150.0;
      case "緑茶":
        return (amountMl / 200.0) * 20.0;
      case "ウーロン茶":
        return (amountMl / 200.0) * 20.0;
      case "ココア":
        return (amountMl / 200.0) * 5.0;
      case "その他":
        return (amountMl / 200.0) * 60.0;
      default:
        return 0.0;
    }
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

      // 今日のカフェイン摂取量を取得（修正版）
      final caffeineResponse = await supabase
          .from('caffeine_records')
          .select('amount_ml, drink_type') // drink_typeも取得
          .eq('user_id', user.id)
          .gte('recorded_at', '${todayString}T00:00:00.000Z')
          .lt(
            'recorded_at',
            '${DateTime(today.year, today.month, today.day + 1).toIso8601String().substring(0, 10)}T00:00:00.000Z',
          );

      double totalCaffeine = 0.0;
      for (final record in caffeineResponse) {
        final amountMl = record['amount_ml'] as int? ?? 0;
        final drinkType = record['drink_type'] as String? ?? 'コーヒー';

        // 飲み物の種類に応じて正確なカフェイン量を計算
        totalCaffeine += calculateCaffeineFromRecord(drinkType, amountMl);
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
        todayCaffeine = totalCaffeine.round();
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
      padding: const EdgeInsets.only(top: 5), // 上部パディングを削減
      child: Row(
        children: [
          // カフェイン摂取量ウィジェット
          Padding(
            padding: const EdgeInsets.only(right: 8), // 右マージンを削減
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), // 角丸を小さく
                    color: Colors.grey[300],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1), // パディングを削減
                    child: Text(
                      "カフェイン",
                      style: TextStyle(
                        fontSize: 10, // フォントサイズを小さく
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2), // 間隔を追加
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Color(0xFFFFA748), width: 3), // ボーダーを細く
                    borderRadius: BorderRadius.circular(15), // 角丸を小さく
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, // 水平パディングを削減
                      vertical: 3, // 垂直パディングを削減
                    ),
                    child: Text(
                      isLoading ? "読込中" : "${todayCaffeine}mg",
                      style: TextStyle(
                        fontSize: 12, // フォントサイズを小さく
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 睡眠時間ウィジェット
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8), // 角丸を小さく
                  color: Colors.grey[300],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1), // パディングを削減
                  child: Text(
                    "睡眠時間",
                    style: TextStyle(
                      fontSize: 10, // フォントサイズを小さく
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2), // 間隔を追加
              Container(
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Color(0xFFFFA748), width: 3), // ボーダーを細く
                  borderRadius: BorderRadius.circular(15), // 角丸を小さく
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, // 水平パディングを削減
                    vertical: 3, // 垂直パディングを削減
                  ),
                  child: Text(
                    isLoading ? "読込中" : todaySleep,
                    style: TextStyle(
                      fontSize: 12, // フォントサイズを小さく
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
