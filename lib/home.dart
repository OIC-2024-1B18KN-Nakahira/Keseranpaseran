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

// ▼ アニメーションを使うために SingleTickerProviderStateMixin を追加
class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // カフェイン摂取量のデータ（mg）
  double? caffeineIntake;

  // 睡眠時間のデータ（時間）
  double? sleepHours;

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

      // usersテーブルからユーザー情報を取得
      final userResponse =
      await supabase.from('users').select('*').eq('id', currentUser.id).single();

      print('User data: $userResponse');

      // 今日の日付を取得
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('Today: $todayString');

      // 今日のカフェイン摂取量を取得（caffeine_recordsテーブルがある場合）
      try {
        final caffeineResponse = await supabase
            .from('caffeine_records')
            .select('amount')
            .eq('user_id', currentUser.id)
            .gte('recorded_at', '${todayString} 00:00:00')
            .lt('recorded_at', '${todayString} 23:59:59');

        print('Caffeine records: $caffeineResponse');

        // 今日のカフェイン摂取量を合計
        double totalCaffeine = 0.0;
        for (var record in caffeineResponse) {
          totalCaffeine += (record['amount'] as num).toDouble();
        }

        print('Total caffeine today: $totalCaffeine mg');

        setState(() {
          caffeineIntake = totalCaffeine;
        });
      } catch (caffeineError) {
        print('カフェインデータ取得エラー: $caffeineError');
        // テーブルが存在しない場合はテストデータを使用
        setState(() {
          caffeineIntake = 450.0; // テスト用
        });
      }

      // 今日の睡眠時間を取得（sleep_recordsテーブルがある場合）
      try {
        final sleepResponse = await supabase
            .from('sleep_records')
            .select('hours')
            .eq('user_id', currentUser.id)
            .gte('recorded_at', '${todayString} 00:00:00')
            .lt('recorded_at', '${todayString} 23:59:59')
            .order('recorded_at', ascending: false)
            .limit(1);

        print('Sleep records: $sleepResponse');

        if (sleepResponse.isNotEmpty) {
          final sleepHours = (sleepResponse[0]['hours'] as num).toDouble();
          print('Sleep hours today: $sleepHours hours');

          setState(() {
            this.sleepHours = sleepHours;
          });
        } else {
          print('今日の睡眠記録がありません');
          setState(() {
            sleepHours = null;
          });
        }
      } catch (sleepError) {
        print('睡眠データ取得エラー: $sleepError');
        // テーブルが存在しない場合はテストデータを使用
        setState(() {
          sleepHours = 6.0; // テスト用（7時間未満）
        });
      }

      print('=== 最終データ ===');
      print('Caffeine Intake: $caffeineIntake mg');
      print('Sleep Hours: $sleepHours hours');
      print('Bad Status: ${isBadHealthStatus()}');
      print('Image Path: ${getStatusImagePath()}');
    } catch (error) {
      print('=== データ取得エラー ===');
      print('Error: $error');

      // エラー時はテストデータを使用
      setState(() {
        caffeineIntake = 450.0; // badStatus.pngが表示されるテストデータ
        sleepHours = 6.0; // badStatus.pngが表示されるテストデータ
      });
    }
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

    // ※元コードのロジックを尊重してそのまま
    // カフェイン摂取量が400mg以上 または 睡眠時間が7時間未満（どちらか一方）
    return (caffeineIntake! >= 400.0 && sleepHours! >= 7.0) ||
        (caffeineIntake! < 400.0 && sleepHours! < 7.0);
  }

  // 健康状態が非常に悪いかどうかを判定する関数（新規追加）
  bool isDeadHealthStatus() {
    if (!hasRequiredData()) {
      return false; // データがない場合は悪い状態ではない
    }

    // カフェイン摂取量が400mg以上 かつ 睡眠時間が7時間未満（両方）
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
                // 状態カード
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
                // 最大摂取量カード
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
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
