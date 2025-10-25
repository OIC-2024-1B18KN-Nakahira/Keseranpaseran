import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keseranpaseran/provider.dart';
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
          padding: const EdgeInsets.only(top: 23, left: 9),
          child: Text(todayText,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayData();
    });
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
      print('=== AppBar: データ取得開始 ===');
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('AppBar: ユーザー未ログイン');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('AppBar: 今日の日付 = $todayString');

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

      print('AppBar: カフェイン合計 = ${totalCaffeine.round()}mg');

      // 今日の睡眠時間を取得（すべての記録を合計）
      final sleepResponse = await supabase
          .from('sleep_records')
          .select('sleep_duration_minutes')
          .eq('user_id', user.id)
          .eq('record_date', todayString);

      print('AppBar: 睡眠レスポンス = $sleepResponse');

      String sleepTime = "0時間";
      if (sleepResponse.isNotEmpty) {
        int totalSleepMinutes = 0;
        for (final record in sleepResponse) {
          final sleepMinutes = record['sleep_duration_minutes'] as int? ?? 0;
          totalSleepMinutes += sleepMinutes;
        }

        print('AppBar: 睡眠合計 = ${totalSleepMinutes}分');

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
      } else {
        print('AppBar: 睡眠データなし');
      }

      print('AppBar: 睡眠表示 = $sleepTime');

      setState(() {
        todayCaffeine = totalCaffeine.round();
        todaySleep = sleepTime;
        isLoading = false;
      });

      print('=== AppBar: データ取得完了 ===');
    } catch (error) {
      print('AppBar: データ取得エラー: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // データ更新通知を監視し、変更時にデータを再取得
    ref.listen<int>(dataUpdateNotifierProvider, (previous, next) {
      print('AppBar: データ更新通知を受信 (previous: $previous, next: $next)');
      if (previous != next) {
        _loadTodayData();
      }
    });

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
                    child: const Text(
                      "カフェイン",
                      style: TextStyle(
                        fontSize: 10, // フォントサイズを小さく
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2), // 間隔を追加
                Container(
                  decoration: BoxDecoration(
                    border: const Border.fromBorderSide(BorderSide(
                        color: Color(0xFFFFA748), width: 3)), // ボーダーを細く
                    borderRadius: BorderRadius.circular(15), // 角丸を小さく
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, // 水平パディングを削減
                      vertical: 3, // 垂直パディングを削減
                    ),
                    child: Text(
                      isLoading ? "読込中" : "${todayCaffeine}mg",
                      style: const TextStyle(
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
                  child: const Text(
                    "睡眠時間",
                    style: TextStyle(
                      fontSize: 10, // フォントサイズを小さく
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2), // 間隔を追加
              Container(
                decoration: BoxDecoration(
                  border: const Border.fromBorderSide(BorderSide(
                      color: Color(0xFFFFA748), width: 3)), // ボーダーを細く
                  borderRadius: BorderRadius.circular(15), // 角丸を小さく
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, // 水平パディングを削減
                    vertical: 3, // 垂直パディングを削減
                  ),
                  child: Text(
                    isLoading ? "読込中" : todaySleep,
                    style: const TextStyle(
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
