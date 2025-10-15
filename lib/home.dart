import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keseranpaseran/history.dart';
import 'package:keseranpaseran/widget/appbar_widget.dart';
import 'package:keseranpaseran/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}


// ▼ アニメーションを使うために SingleTickerProviderStateMixin を追加
class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // カフェイン摂取量のデータ（mg）
  double? caffeineIntake;
  double? sleepHours;
  bool _isLoading = false;

  // ===== ここから浮遊アニメーション用のフィールド =====
  // 画像の上下アニメーション用コントローラ
  late final AnimationController _floatCtrl;

  // 上下位置（Y方向）を表すアニメーション値（-10px ～ +10px を往復）
  late final Animation<double> _floatAnim;
  // ===== ここまで浮遊アニメーション用のフィールド =====

  @override
  void initState() {
    super.initState();

    // ▼ 浮遊アニメーションの初期化
    // 3秒かけてゆっくり上下に移動して、reverse:true で行ったり来たりを繰り返す
    _floatCtrl = AnimationController(
      vsync: this, // Ticker をこの State から供給
      duration: const Duration(seconds: 3),
    );

    // -10px から +10px の範囲をイージング（ゆっくり）で往復
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _floatCtrl,
        curve: Curves.easeInOut,
      ),
    );

    // アニメーション開始（往復）
    _floatCtrl.repeat(reverse: true);

    // 実際のデータ取得処理をここに記述
    loadUserData();
  }

  @override
  void dispose() {
    // アニメーションコントローラは必ず破棄
    _floatCtrl.dispose();
    super.dispose();
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

      print('Current User ID: ${currentUser.id}');

      // usersテーブルからユーザー情報を取得
      final userResponse =
      await supabase.from('users').select('*').eq('id', currentUser.id).single();

      print('User data: $userResponse');

      // 今日の日付を取得
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
  bool hasRequiredData() {
    return caffeineIntake != null && sleepHours != null;
  }

  // カフェイン摂取基準を取得（妊娠状態を考慮）
  double getCaffeineLimit() {
    final isPregnant = ref.read(provider.pregnantProvider);
    return isPregnant ? 200.0 : 400.0;
  }

  // 健康状態が悪いかどうかを判定
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

    // ※元コードのロジックを尊重してそのまま
    // カフェイン摂取量が400mg以上 または 睡眠時間が7時間未満（どちらか一方）
    return (caffeineIntake! >= 400.0 && sleepHours! >= 7.0) ||
        (caffeineIntake! < 400.0 && sleepHours! < 7.0);
  }

  // 健康状態が非常に悪いかどうかを判定
  bool isDeadHealthStatus() {
    if (!hasRequiredData()) {
      return false;
    }

    final caffeineLimit = getCaffeineLimit();
    return caffeineIntake! >= caffeineLimit && sleepHours! < 7.0;
  }

  // 表示する画像のパスを決定
  String getStatusImagePath() {
    if (!hasRequiredData()) {
      return 'assets/goodStatus.png';
    } else if (isDeadHealthStatus()) {
      return 'assets/deadStatus.png';
    } else if (isBadHealthStatus()) {
      return 'assets/badStatus.png';
    } else {
      return 'assets/goodStatus.png';
    }
  }

  // メッセージを取得
  String getStatusMessage() {
    if (!hasRequiredData()) {
      return 'データがありません';
    } else if (isDeadHealthStatus()) {
      return 'カフェイン過剰摂取と睡眠が足りないよ';
    } else if (isBadHealthStatus()) {
      final caffeineLimit = getCaffeineLimit();
      if (caffeineIntake! >= caffeineLimit) {
        return 'カフェインの取り過ぎだ';
      } else {
        return '睡眠が足りません';
      }
    } else {
      return '健康状態は良好です';
    }
  }

  // 状態テキストを取得
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

  // 残りカフェイン摂取量を計算
  double getRemainingCaffeine() {
    if (caffeineIntake == null) {
      return getCaffeineLimit();
    }
    return getCaffeineLimit() - caffeineIntake!;
  }

  // 残りカフェイン摂取量のウィジェット
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

  // 背景色を取得
  Color getBackgroundColor() {
    if (!hasRequiredData()) {
      // データがない場合は良好状態の色
      return const Color(0xFF8EFF3C);
    } else if (isDeadHealthStatus()) {
      // 非常に悪い健康状態の場合（カフェイン過剰＋睡眠不足）
      return const Color(0xFFBAB5B5);
    } else if (isBadHealthStatus()) {
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
    ref.watch(provider.dataUpdateNotifierProvider);

    // カスタムアプリ名を取得
    final user = supabase.auth.currentUser;
    final customAppName = user?.userMetadata?['app_name'] ?? 'ケセランパセラン';

    print('=== BUILD実行 ===');
    print('カフェイン: $caffeineIntake');
    print('睡眠: $sleepHours');
    print('ローディング: $_isLoading');
    print('画像: ${getStatusImagePath()}');
    print('背景色: ${getBackgroundColor()}');

    return Scaffold(
      appBar: AppBar(title: const Calendar(), actions: const [AppTitle()]),
      backgroundColor: getBackgroundColor(), // 背景色を健康状態に応じて変更
      body: Column(
        children: [
          // 上部の余白
          const SizedBox(height: 24),

          // ▼ 画像を上下に“浮かせる”アニメーション
          // AnimatedBuilder で _floatAnim の値に応じて Y 方向に平行移動させる
          Center(
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (context, child) {
                return Transform.translate(
                  // Yだけ動かす（Xは0）
                  offset: Offset(0, _floatAnim.value),
                  child: child,
                );
              },
              // child には元々の Image.asset をそのまま入れる
              child: Image.asset(
                getStatusImagePath(),
                width: 220, // 必要に応じて調整
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 16), // ケセランパセラ ラベル
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 153, 8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'ケセランパセラン',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),

          const SizedBox(height: 8), // 下部の余白
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

          // 下部の2つのカード
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
                            color: Color.fromARGB(255, 0, 0, 0),
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
