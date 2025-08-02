import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keseranpaseran/widget/appbar_widget.dart';
import 'package:keseranpaseran/provider.dart';
import 'package:keseranpaseran/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  double? caffeineIntake;
  double? sleepHours;

  @override
  void initState() {
    super.initState();
    // リアルタイムコールバックを設定
    RealtimeService.setCaffeineCallback(_onCaffeineDataChanged);
    RealtimeService.setSleepCallback(_onSleepDataChanged);

    // 初期データ読み込み
    loadUserData();
  }

  // カフェインデータ変更時のコールバック
  void _onCaffeineDataChanged(Map<String, dynamic> payload) {
    print('Home: カフェインデータが変更されました');
    loadUserData(); // データを再読み込み
  }

  // 睡眠データ変更時のコールバック
  void _onSleepDataChanged(Map<String, dynamic> payload) {
    print('Home: 睡眠データが変更されました');
    loadUserData(); // データを再読み込み
  }

  @override
  void dispose() {
    // コールバックをクリア
    RealtimeService.setCaffeineCallback((_) {});
    RealtimeService.setSleepCallback((_) {});
    super.dispose();
  }

  // ユーザーデータを読み込む関数
  Future<void> loadUserData() async {
    try {
      print('=== ユーザーデータ取得開始 ===');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('ユーザーがログインしていません');
        setState(() {
          caffeineIntake = null;
          sleepHours = null;
        });
        return;
      }

      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 今日のカフェイン摂取量を取得
      try {
        final caffeineResponse = await supabase
            .from('caffeine_records')
            .select('amount_ml')
            .eq('user_id', currentUser.id)
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

        setState(() {
          caffeineIntake = totalCaffeine.toDouble();
        });
      } catch (caffeineError) {
        print('カフェインデータ取得エラー: $caffeineError');
        setState(() {
          caffeineIntake = 0.0;
        });
      }

      // 今日の睡眠時間を取得（すべての記録を合計）
      try {
        final sleepResponse = await supabase
            .from('sleep_records')
            .select('sleep_duration_minutes')
            .eq('user_id', currentUser.id)
            .eq('record_date', todayString);

        if (sleepResponse.isNotEmpty) {
          int totalSleepMinutes = 0;
          for (var record in sleepResponse) {
            final sleepMinutes = record['sleep_duration_minutes'] as int? ?? 0;
            totalSleepMinutes += sleepMinutes;
          }

          double totalSleepHours = totalSleepMinutes / 60.0;

          setState(() {
            sleepHours = totalSleepHours;
          });
        } else {
          setState(() {
            sleepHours = null;
          });
        }
      } catch (sleepError) {
        print('睡眠データ取得エラー: $sleepError');
        setState(() {
          sleepHours = 0.0;
        });
      }

      // データ更新を他の画面に通知
      notifyDataUpdate(ref);
    } catch (error) {
      print('データ取得エラー: $error');
      setState(() {
        caffeineIntake = 0.0;
        sleepHours = 0.0;
      });
    }
  }

  // 健康状態をデバッグ出力する関数
  void debugHealthStatus() {
    print('=== 健康状態デバッグ ===');
    print('Has required data: ${hasRequiredData()}');
    print('Is bad health status: ${isBadHealthStatus()}');
    print('Is dead health status: ${isDeadHealthStatus()}');
    print('Status message: ${getStatusMessage()}');
    print('Status text: ${getStatusText()}');
    print('Background color: ${getBackgroundColor()}');
    print('Image path: ${getStatusImagePath()}');
  }

  // データが存在するかチェックする関数
  bool hasRequiredData() {
    return caffeineIntake != null && sleepHours != null;
  }

  // 健康状態が悪いかどうかを判定する関数
  bool isBadHealthStatus() {
    if (!hasRequiredData()) {
      return false; // データがない場合は悪い状態ではない
    }

    final isCaffeineExcessive = caffeineIntake! >= 400.0;
    final isSleepInsufficient = sleepHours! < 7.0;

    // Dead Status（両方が悪い）の場合は Bad Status ではない
    if (isDeadHealthStatus()) {
      return false;
    }

    // どちらか一方だけが悪い場合のみ Bad Status
    return isCaffeineExcessive || isSleepInsufficient;
  }

  // 健康状態が非常に悪いかどうかを判定する関数（新規追加）
  bool isDeadHealthStatus() {
    if (!hasRequiredData()) {
      return false; // データがない場合は悪い状態ではない
    }

    // カフェイン過剰（400mg以上）かつ睡眠不足（7時間未満）
    return caffeineIntake! >= 400.0 && sleepHours! < 7.0;
  }

  // 表示する画像のパスを決定する関数
  String getStatusImagePath() {
    if (!hasRequiredData()) {
      // データがない場合は良好状態の画像
      return 'assets/goodStatus.png';
    } else if (isDeadHealthStatus()) {
      // 非常に悪い健康状態の場合（カフェイン過剰＋睡眠不足）
      return 'assets/deadStatus.png';
    } else if (isBadHealthStatus()) {
      // 悪い健康状態の場合（どちらか一方）
      return 'assets/badStatus.png';
    } else {
      // データがあって健康状態が良い場合
      return 'assets/goodStatus.png';
    }
  }

  // メッセージを取得する関数
  String getStatusMessage() {
    if (!hasRequiredData()) {
      return 'データがありません';
    } else if (isDeadHealthStatus()) {
      return 'カフェイン過剰摂取と睡眠が足りないよ';
    } else if (isBadHealthStatus()) {
      // どちらか一方の問題がある場合
      if (caffeineIntake! >= 400.0) {
        return 'カフェインの取り過ぎだ';
      } else {
        return '睡眠が足りません';
      }
    } else {
      return '健康状態は良好です';
    }
  }

  // 状態テキストを取得する関数
  String getStatusText() {
    if (!hasRequiredData()) {
      return 'ふつう';
    } else if (isDeadHealthStatus()) {
      return 'すごく悪い';
    } else if (isBadHealthStatus()) {
      return 'わるい';
    } else {
      return 'とても良い';
    }
  }

  // 残りカフェイン摂取量を計算する関数
  double getRemainingCaffeine() {
    if (caffeineIntake == null) {
      return 400.0; // データがない場合は400mg
    }
    return 400.0 - caffeineIntake!;
  }

  // 残りカフェイン摂取量のテキストと色を取得する関数
  Widget getRemainingCaffeineWidget() {
    final remaining = getRemainingCaffeine();
    final isNegative = remaining < 0;

    return Text(
      '残り\n${remaining.toInt()}mg/日',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isNegative ? Colors.red : Colors.black,
        fontWeight: isNegative ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // 背景色を取得する関数（新規追加）
  Color getBackgroundColor() {
    if (!hasRequiredData()) {
      // データがない場合は良好状態の色
      return Color(0xFF8EFF3C);
    } else if (isDeadHealthStatus()) {
      // 非常に悪い健康状態の場合（カフェイン過剰＋睡眠不足）
      return Color(0xFFBAB5B5);
    } else if (isBadHealthStatus()) {
      // 悪い健康状態の場合（どちらか一方）
      return Color(0xFF0070D9);
    } else {
      // データがあって健康状態が良い場合
      return Color(0xFF8EFF3C);
    }
  }

  @override
  Widget build(BuildContext context) {
    // データ更新通知を監視
    ref.watch(dataUpdateNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Calendar(), actions: [AppTitle()]),
      backgroundColor: getBackgroundColor(),
      body: Column(
        children: [
          SizedBox(height: 24),
          Center(
            child: Image.asset(
              getStatusImagePath(),
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 153, 8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'ケセランパセラン',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              getStatusMessage(),
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 252, 249, 250),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '状態',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 245, 144, 21),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(getStatusText()),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(31, 0, 0, 0),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '悪影響のない\n最大摂取量',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        getRemainingCaffeineWidget(),
                      ],
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
