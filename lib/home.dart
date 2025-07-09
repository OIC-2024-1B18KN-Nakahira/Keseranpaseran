import 'package:flutter/material.dart';
import 'package:keseranpaseran/widget/appbar_widget.dart';

import 'HistoryModels/caffeine_record.dart';
import 'HistoryModels/sleep_record.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}
bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _HomeState extends State<Home> {
  // ダミーデータ（本当は実際のデータに置き換え）
  final List<SleepRecord> dummySleepRecords = [
    SleepRecord(date: DateTime.now(), duration: Duration(hours: 7, minutes: 30))
  ];
  final List<CaffeineRecord> dummyCaffeineRecords = [
    CaffeineRecord(date: DateTime.now(), mg: 200)
  ];

  // 今日の記録状態を返す関数
  String getTodayState() {
    DateTime today = DateTime.now();
    bool hasSleep = dummySleepRecords.any((record) => isSameDate(record.date, today));
    bool hasCaffeine = dummyCaffeineRecords.any((record) => isSameDate(record.date, today));
    if (!hasSleep && !hasCaffeine) {
      return "死んでる"; // どちらもなければ死んでるモーション
    } else if (hasSleep && hasCaffeine) {
      return "健康的"; // 両方ある場合はgood
    } else {
      return "悪い"; // 片方のみであればbad
    }
  }

  // 状態に応じた画像のパスを返す関数
  String getStateImage() {
    final state = getTodayState();
    if (state == "死んでる") {
      return "assets/KeseranPaseran/KeseranpaseranDie.png";
    } else if (state == "健康的") {
      return "assets/KeseranPaseran/KeseranpaseranGood.png";
    } else {
      return "assets/KeseranPaseran/KeseranpaseranBad.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Calendar(), actions: [AppTitle()]),
      backgroundColor: Colors.green, // 背景色を緑に設定
      body: Column(
        children: [
          //上部の余白
          SizedBox(height: 24),
          //画像を表示
          Center(
            child: Image.asset(
              getStateImage(),
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
            child: Text('カフェインの取り過ぎだ', style: TextStyle(fontSize: 16)),
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
                        Text(getTodayState()),
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
                        Text('残り\n00mg/日', textAlign: TextAlign.center),
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
