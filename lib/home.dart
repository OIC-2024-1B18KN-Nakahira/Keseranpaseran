import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
<<<<<<< HEAD
import 'package:keseranpaseran/history.dart';
import 'package:keseranpaseran/widget/appbar_widget.dart';
import 'package:keseranpaseran/provider.dart' as provider;
=======
import 'package:keseranpaseran/widget/appbar_widget.dart';
import 'package:keseranpaseran/provider.dart';
import 'package:keseranpaseran/realtime_service.dart';
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
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
<<<<<<< HEAD
  bool _isLoading = false;
=======
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD

    print('=== Home画面初期化開始 ===');

=======
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
    // リアルタイムコールバックを設定
    RealtimeService.setCaffeineCallback(_onCaffeineDataChanged);
    RealtimeService.setSleepCallback(_onSleepDataChanged);

<<<<<<< HEAD
    print('リアルタイムコールバック設定完了');

    // 初期データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserData();
    });
=======
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
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
  }

  @override
  void dispose() {
<<<<<<< HEAD
    print('=== Home画面終了 ===');
    super.dispose();
  }

  // カフェインデータ変更時のコールバック
  void _onCaffeineDataChanged(Map<String, dynamic> payload) async {
    print('=== カフェインデータ変更検出 ===');
    print('Payload: $payload');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      // データを再取得
      await loadUserData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        print('UI更新完了');
        debugHealthStatus();
      }
    }
  }

  // 睡眠データ変更時のコールバック
  void _onSleepDataChanged(Map<String, dynamic> payload) async {
    print('=== 睡眠データ変更検出 ===');
    print('Payload: $payload');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      // データを再取得
      await loadUserData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        print('UI更新完了');
        debugHealthStatus();
      }
    }
  }

  // ユーザーデータを読み込む関数
  Future<void> loadUserData() async {
    try {
      print('=== ユーザーデータ取得開始 ===');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('ユーザーがログインしていません');
        if (mounted) {
          setState(() {
            caffeineIntake = null;
            sleepHours = null;
          });
        }
        return;
      }

      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('今日の日付: $todayString');
      print('ユーザーID: ${currentUser.id}');

      // 今日のカフェイン摂取量を取得
      try {
        final caffeineResponse = await supabase
            .from('caffeine_records')
            .select('amount_ml, drink_type')
            .eq('user_id', currentUser.id)
            .gte('recorded_at', '${todayString}T00:00:00.000Z')
            .lt('recorded_at',
                '${DateTime(today.year, today.month, today.day + 1).toIso8601String().substring(0, 10)}T00:00:00.000Z');

        print('カフェインレスポンス: $caffeineResponse');

        double totalCaffeine = 0.0;
        for (final record in caffeineResponse) {
          final amountMl = record['amount_ml'] as int? ?? 0;
          final drinkType = record['drink_type'] as String? ?? 'コーヒー';

          final caffeineFromRecord =
              calculateCaffeineFromRecord(drinkType, amountMl);
          totalCaffeine += caffeineFromRecord;

          print('記録: $drinkType ${amountMl}ml → ${caffeineFromRecord}mg');
        }

        print('合計カフェイン: ${totalCaffeine}mg');

        if (mounted) {
          setState(() {
            caffeineIntake = totalCaffeine;
          });
        }
      } catch (caffeineError) {
        print('カフェインデータ取得エラー: $caffeineError');
        if (mounted) {
          setState(() {
            caffeineIntake = 0.0;
          });
        }
      }

      // 今日の睡眠時間を取得
      try {
        final sleepResponse = await supabase
            .from('sleep_records')
            .select('sleep_duration_minutes')
            .eq('user_id', currentUser.id)
            .eq('record_date', todayString);

        print('睡眠レスポンス: $sleepResponse');

        if (sleepResponse.isNotEmpty) {
          int totalSleepMinutes = 0;
          for (var record in sleepResponse) {
            final sleepMinutes = record['sleep_duration_minutes'] as int? ?? 0;
            totalSleepMinutes += sleepMinutes;
          }

          double totalSleepHours = totalSleepMinutes / 60.0;
          print('合計睡眠時間: ${totalSleepHours}時間');

          if (mounted) {
            setState(() {
              sleepHours = totalSleepHours;
            });
          }
        } else {
          print('睡眠データなし');
          if (mounted) {
            setState(() {
              sleepHours = null;
            });
          }
        }
      } catch (sleepError) {
        print('睡眠データ取得エラー: $sleepError');
        if (mounted) {
          setState(() {
            sleepHours = 0.0;
          });
        }
      }

      print('=== データ取得完了 ===');
      print('カフェイン: ${caffeineIntake}mg');
      print('睡眠: ${sleepHours}時間');

      // 他の画面にデータ更新を通知
      provider.notifyDataUpdate(ref);
    } catch (error) {
      print('データ取得エラー: $error');
      if (mounted) {
        setState(() {
          caffeineIntake = 0.0;
          sleepHours = 0.0;
        });
      }
    }
  }

  // カフェイン計算関数
=======
    // コールバックをクリア
    RealtimeService.setCaffeineCallback((_) {});
    RealtimeService.setSleepCallback((_) {});
    super.dispose();
  }

  // カフェイン計算関数を追加
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
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

<<<<<<< HEAD
  // 健康状態をデバッグ出力する関数
  void debugHealthStatus() {
    print('=== 健康状態デバッグ ===');
    print('データ有無: ${hasRequiredData()}');
    print('悪い状態: ${isBadHealthStatus()}');
    print('非常に悪い状態: ${isDeadHealthStatus()}');
    print('メッセージ: ${getStatusMessage()}');
    print('状態テキスト: ${getStatusText()}');
    print('背景色: ${getBackgroundColor()}');
    print('画像パス: ${getStatusImagePath()}');
  }

  // データが存在するかチェック
=======
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

      // 今日のカフェイン摂取量を取得（修正版）
      try {
        final caffeineResponse = await supabase
            .from('caffeine_records')
            .select('amount_ml, drink_type') // drink_typeも取得
            .eq('user_id', currentUser.id)
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

        setState(() {
          caffeineIntake = totalCaffeine;
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
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
  bool hasRequiredData() {
    return caffeineIntake != null && sleepHours != null;
  }

<<<<<<< HEAD
  // カフェイン摂取基準を取得（妊娠状態を考慮）
  double getCaffeineLimit() {
    final isPregnant = ref.read(provider.pregnantProvider);
    return isPregnant ? 200.0 : 400.0;
  }

  // 健康状態が悪いかどうかを判定
=======
  // カフェイン摂取基準を取得
  double getCaffeineLimit() {
    final user = supabase.auth.currentUser;
    final isPregnant = ref.read(pregnantProvider);

    // 妊娠中の場合は200mg、そうでなければ400mg
    return isPregnant ? 200.0 : 400.0;
  }

  // 健康状態が悪いかどうかを判定する関数（修正版）
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
  bool isBadHealthStatus() {
    if (!hasRequiredData()) {
      return false;
    }

    final caffeineLimit = getCaffeineLimit();
    final isCaffeineExcessive = caffeineIntake! >= caffeineLimit;
    final isSleepInsufficient = sleepHours! < 7.0;

    if (isDeadHealthStatus()) {
      return false;
    }

    return isCaffeineExcessive || isSleepInsufficient;
  }

<<<<<<< HEAD
  // 健康状態が非常に悪いかどうかを判定
=======
  // 健康状態が非常に悪いかどうかを判定する関数（修正版）
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
  bool isDeadHealthStatus() {
    if (!hasRequiredData()) {
      return false;
    }

    final caffeineLimit = getCaffeineLimit();
    return caffeineIntake! >= caffeineLimit && sleepHours! < 7.0;
  }

<<<<<<< HEAD
  // 表示する画像のパスを決定
  String getStatusImagePath() {
    if (!hasRequiredData()) {
      return 'assets/goodStatus.png';
    } else if (isDeadHealthStatus()) {
      return 'assets/deadStatus.png';
    } else if (isBadHealthStatus()) {
      return 'assets/badStatus.png';
    } else {
=======
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
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
      return 'assets/goodStatus.png';
    }
  }

<<<<<<< HEAD
  // メッセージを取得
=======
  // メッセージを取得する関数
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
  String getStatusMessage() {
    if (!hasRequiredData()) {
      return 'データがありません';
    } else if (isDeadHealthStatus()) {
      return 'カフェイン過剰摂取と睡眠が足りないよ';
    } else if (isBadHealthStatus()) {
<<<<<<< HEAD
      final caffeineLimit = getCaffeineLimit();
      if (caffeineIntake! >= caffeineLimit) {
=======
      // どちらか一方の問題がある場合
      if (caffeineIntake! >= 400.0) {
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
        return 'カフェインの取り過ぎだ';
      } else {
        return '睡眠が足りません';
      }
    } else {
      return '健康状態は良好です';
    }
  }

<<<<<<< HEAD
  // 状態テキストを取得
=======
  // 状態テキストを取得する関数
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
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

<<<<<<< HEAD
  // 残りカフェイン摂取量を計算
=======
  // 残りカフェイン摂取量を計算する関数（修正版）
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
  double getRemainingCaffeine() {
    if (caffeineIntake == null) {
      return getCaffeineLimit();
    }
    return getCaffeineLimit() - caffeineIntake!;
  }

<<<<<<< HEAD
  // 残りカフェイン摂取量のウィジェット
=======
  // 残りカフェイン摂取量のテキストと色を取得する関数
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
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

<<<<<<< HEAD
  // 背景色を取得
=======
  // 背景色を取得する関数（新規追加）
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
  Color getBackgroundColor() {
    if (!hasRequiredData()) {
      // データがない場合は良好状態の色
      return const Color(0xFF8EFF3C);
    } else if (isDeadHealthStatus()) {
      // 非常に悪い健康状態の場合（カフェイン過剰＋睡眠不足）
      return const Color(0xFFBAB5B5);
    } else if (isBadHealthStatus()) {
<<<<<<< HEAD
      return Color(0xFF0070D9);
=======
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
      // 悪い健康状態の場合（どちらか一方）
      return const Color(0xFF0070D9);
    } else {
      // データがあって健康状態が良い場合
      return const Color(0xFF8EFF3C);
    }
  }

  @override
  Widget build(BuildContext context) {
    // データ更新通知を監視
<<<<<<< HEAD
    ref.watch(provider.dataUpdateNotifierProvider);
=======
    ref.watch(dataUpdateNotifierProvider);
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8

    // カスタムアプリ名を取得
    final user = supabase.auth.currentUser;
    final customAppName = user?.userMetadata?['app_name'] ?? 'ケセランパセラン';

<<<<<<< HEAD
    print('=== BUILD実行 ===');
    print('カフェイン: $caffeineIntake');
    print('睡眠: $sleepHours');
    print('ローディング: $_isLoading');
    print('画像: ${getStatusImagePath()}');
    print('背景色: ${getBackgroundColor()}');

=======
>>>>>>> 911a46959a419d4eb9fb91803ae4249b2e8d51e8
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft, // 左寄せに設定
          child: Calendar(),
        ),
        actions: [AppTitle()],
      ),
      backgroundColor: getBackgroundColor(),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Image.asset(
              getStatusImagePath(),
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 153, 8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              customAppName, // カスタムアプリ名を表示
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              getStatusMessage(),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 252, 249, 250),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '状態',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 245, 144, 21),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(getStatusText()),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(31, 0, 0, 0),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '悪影響のない\n最大摂取量',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
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
