import 'package:flutter/material.dart';
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

class AppTitle extends StatefulWidget {
  const AppTitle({super.key});

  @override
  State<AppTitle> createState() => _AppTitleState();
}

class _AppTitleState extends State<AppTitle> {
  int todayCaffeine = 0;
  String todaySleep = "0時間";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
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

      // カフェイン摂取量を合計（mlをmgに変換）
      int totalCaffeine = 0;
      for (final record in caffeineResponse) {
        final amountMl = record['amount_ml'] as int? ?? 0;
        // 1mlあたり0.4mgのカフェインと仮定
        totalCaffeine += (amountMl * 0.4).round();
      }

      // 今日の睡眠時間を取得
      final sleepResponse = await supabase
          .from('sleep_records')
          .select('sleep_duration_minutes')
          .eq('user_id', user.id)
          .eq('record_date', todayString);

      String sleepTime = "0時間";
      if (sleepResponse.isNotEmpty) {
        final sleepMinutes =
            sleepResponse.first['sleep_duration_minutes'] as int? ?? 0;
        final hours = sleepMinutes ~/ 60;
        final minutes = sleepMinutes % 60;
        sleepTime = minutes > 0 ? "${hours}時間${minutes}分" : "${hours}時間";
      }

      setState(() {
        todayCaffeine = totalCaffeine;
        todaySleep = sleepTime;
        isLoading = false;
      });
    } catch (error) {
      print('データ取得エラー: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
