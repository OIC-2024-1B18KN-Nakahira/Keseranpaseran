import 'package:flutter/material.dart';
import 'package:keseranpaseran/widget/appbar_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabaseクライアントを取得
final supabase = Supabase.instance.client;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // カフェイン摂取量のデータ（mg）
  double? caffeineIntake;

  // 睡眠時間のデータ（時間）
  double? sleepHours;

  @override
  void initState() {
    super.initState();
    // 実際のデータ取得処理をここに記述
    loadUserData();
  }

  // ユーザーデータを読み込む関数
  Future<void> loadUserData() async {
    try {
      print('=== ユーザーデータ取得開始 ===');

      // 現在ログイン中のユーザーIDを取得
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('ユーザーがログインしていません');
        setState(() {
          caffeineIntake = null;
          sleepHours = null;
        });
        return;
      }

      print('Current User ID: ${currentUser.id}');

      // 今日の日付を取得
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('Today: $todayString');

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

        print('Caffeine records: $caffeineResponse');

        // 今日のカフェイン摂取量を合計（mlをmgに変換）
        int totalCaffeine = 0;
        for (final record in caffeineResponse) {
          final amountMl = record['amount_ml'] as int? ?? 0;
          // 1mlあたり0.4mgのカフェインと仮定
          totalCaffeine += (amountMl * 0.4).round();
        }

        print('Total caffeine today: $totalCaffeine mg');

        setState(() {
          caffeineIntake = totalCaffeine.toDouble();
        });
      } catch (caffeineError) {
        print('カフェインデータ取得エラー: $caffeineError');
        setState(() {
          caffeineIntake = 450.0; // テスト用
        });
      }

      // 今日の睡眠時間を取得（すべての記録を合計）
      try {
        final sleepResponse = await supabase
            .from('sleep_records')
            .select('sleep_duration_minutes')
            .eq('user_id', currentUser.id)
            .eq('record_date', todayString);

        print('Sleep records: $sleepResponse');

        if (sleepResponse.isNotEmpty) {
          // 今日のすべての睡眠記録を合計（分単位）
          int totalSleepMinutes = 0;
          for (var record in sleepResponse) {
            final sleepMinutes = record['sleep_duration_minutes'] as int? ?? 0;
            totalSleepMinutes += sleepMinutes;
            print('Sleep record: ${sleepMinutes}分');
          }

          // 分を時間に変換
          double totalSleepHours = totalSleepMinutes / 60.0;

          print('Total sleep minutes today: ${totalSleepMinutes}分');
          print('Total sleep hours today: ${totalSleepHours}時間');
          print('Sleep records count: ${sleepResponse.length}件');

          setState(() {
            sleepHours = totalSleepHours;
          });
        } else {
          print('今日の睡眠記録がありません');
          setState(() {
            sleepHours = null;
          });
        }
      } catch (sleepError) {
        print('睡眠データ取得エラー: $sleepError');
        setState(() {
          sleepHours = 6.0; // テスト用（7時間未満）
        });
      }

      print('=== 最終データ ===');
      print('Caffeine Intake: $caffeineIntake mg');
      print('Sleep Hours: $sleepHours hours');

      // 健康状態のデバッグ
      debugHealthStatus();
    } catch (error) {
      print('=== データ取得エラー ===');
      print('Error: $error');

      // エラー時はテストデータを使用
      setState(() {
        caffeineIntake = 450.0;
        sleepHours = 6.0;
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
    return Scaffold(
      appBar: AppBar(title: Calendar(), actions: [AppTitle()]),
      backgroundColor: getBackgroundColor(), // 背景色を健康状態に応じて変更
      body: Column(
        children: [
          //上部の余白
          SizedBox(height: 24),
          //画像を表示（データの有無と健康状態に応じて切り替え）
          Center(
            child: Image.asset(
              getStatusImagePath(),
              width: 220, // 必要に応じて調整
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 16), //ケセランパセララベル
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
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          SizedBox(height: 8), //下部の余白
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
          // 下部の2つのカード
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 状態カード
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
                // 最大摂取量カード
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
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
                            color: const Color.fromARGB(255, 0, 0, 0),
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
