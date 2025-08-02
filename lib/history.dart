import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keseranpaseran/services/realtime_service.dart';

/* --------------------------------------------------
 * 履歴画面  ― 睡眠時間 ＆ カフェイン摂取量
 * ・グラフは「右端＝最新日／左へ行くほど古い」
 * ・表示対象は最新日を含む直近 7 日固定
 * ・データが無い日は 0 で補完して描画
 * -------------------------------------------------- */

final supabase = Supabase.instance.client;

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  /// 0 = Sleep / 1 = Caffeine
  int _mode = 0;

  List<_Sleep> _sleep = [];
  List<_Caf> _caf = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // リアルタイムコールバックを設定
    RealtimeService.setCaffeineCallback(_onDataChanged);
    RealtimeService.setSleepCallback(_onDataChanged);

    _loadData();
  }

  /* ---------------- Supabaseからデータを取得 ---------------- */

  Future<void> _loadData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 睡眠データを取得
      final sleepResponse = await supabase
          .from('sleep_records')
          .select()
          .eq('user_id', user.id)
          .order('record_date', ascending: false);

      // カフェインデータを取得
      final caffeineResponse = await supabase
          .from('caffeine_records')
          .select()
          .eq('user_id', user.id)
          .order('recorded_at', ascending: false);

      setState(() {
        // 睡眠データを変換
        _sleep =
            sleepResponse.map<_Sleep>((record) {
              final recordDate = DateTime.parse(record['record_date']);
              final durationMinutes =
                  record['sleep_duration_minutes'] as int? ?? 0;
              final duration = Duration(minutes: durationMinutes);
              return _Sleep(recordDate, duration);
            }).toList();

        // カフェインデータを変換・集計（同じ日のデータを合計）
        final caffeineMap = <String, int>{};
        for (final record in caffeineResponse) {
          final recordedAt = DateTime.parse(record['recorded_at']);
          final date = DateTime(
            recordedAt.year,
            recordedAt.month,
            recordedAt.day,
          );
          final dateKey = _key(date);
          final amountMl = record['amount_ml'] as int? ?? 0;

          // mlをmgに変換（コーヒー1mlあたり約0.4mgのカフェインと仮定）
          final caffeineMg = (amountMl * 0.4).round();

          caffeineMap[dateKey] = (caffeineMap[dateKey] ?? 0) + caffeineMg;
        }

        _caf =
            caffeineMap.entries.map((entry) {
              final dateParts = entry.key.split('-');
              final date = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
              return _Caf(date, entry.value);
            }).toList();

        // 日付順にソート
        _caf.sort((a, b) => b.date.compareTo(a.date));

        _isLoading = false;
      });
    } catch (error) {
      print('データ取得エラー: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /* ---------- 共通ヘルパー ---------- */

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  DateTime _toDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDur(Duration d) => '${d.inHours}h${d.inMinutes.remainder(60)}m';
  String _fmtMg(int mg) => '${mg}mg';

  /* ---------- グラフ専用 Getter（最新から 7 日固定） ---------- */

  List<_Sleep> get _sleepGraph {
    if (_sleep.isEmpty) return [];
    final latestDay = _toDay(
      _sleep.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date,
    );

    final map = {for (var e in _sleep) _key(e.date): e};

    // latestDay - 6 〜 latestDay の 7 日分（古 → 新）
    return List.generate(7, (i) {
      final d = latestDay.subtract(Duration(days: 6 - i));
      return map[_key(d)] ?? _Sleep(d, Duration.zero);
    });
  }

  List<_Caf> get _cafGraph {
    if (_caf.isEmpty) return [];
    final latestDay = _toDay(
      _caf.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date,
    );

    final map = {for (var e in _caf) _key(e.date): e};

    return List.generate(7, (i) {
      final d = latestDay.subtract(Duration(days: 6 - i));
      return map[_key(d)] ?? _Caf(d, 0);
    });
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('履歴'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('履歴'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ToggleButtons(
                isSelected: [_mode == 0, _mode == 1],
                borderRadius: BorderRadius.circular(8),
                onPressed: (i) => setState(() => _mode = i),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('睡眠'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('カフェイン'),
                  ),
                ],
              ),
            ),
            Expanded(child: _mode == 0 ? _sleepView() : _caffeineView()),
          ],
        ),
      ),
    );
  }

  /* -------------------- 睡眠ビュー -------------------- */
  Widget _sleepView() {
    final graphList = _sleepGraph; // 7 日（古 → 新）
    final recordList = _sleep; // 全件

    return Column(
      children: [
        /* ---- 折れ線グラフ ---- */
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                graphList.isEmpty
                    ? const Center(child: Text('グラフデータなし'))
                    : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: 24,
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        // タッチしたときの挙動
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor:
                                (LineBarSpot spot) => Colors.blueGrey,
                            getTooltipItems:
                                (spots) =>
                                    spots.map((s) {
                                      final idx = s.x.toInt();
                                      return LineTooltipItem(
                                        _fmtDur(graphList[idx].dur), // 例: 7h40m
                                        const TextStyle(color: Colors.white),
                                      );
                                    }).toList(),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= graphList.length) {
                                  return const SizedBox.shrink();
                                }
                                // 右端＝最新へ反転
                                final d = graphList[i].date;
                                return Text(
                                  '${d.month}/${d.day}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: false,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.blue.withAlpha(77), // 0.3 * 255
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            spots: [
                              for (var i = 0; i < graphList.length; i++)
                                FlSpot(
                                  i.toDouble(),
                                  graphList[i].dur.inMinutes / 60.0, // ★ ここだけ変更
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
          ),
        ),
        /* ---- リスト（全件） ---- */
        Expanded(
          child:
              recordList.isEmpty
                  ? const Center(child: Text('睡眠データがありません'))
                  : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: recordList.length,
                    itemBuilder: (_, i) {
                      final d = recordList[i];
                      final h = d.dur.inHours;
                      final m = d.dur.inMinutes.remainder(60);
                      return _RecordTile(
                        date: d.date,
                        value: '${h}h${m}m',
                        highlight: h >= 12,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                  ),
        ),
      ],
    );
  }

  /* ----------------- カフェインビュー ----------------- */
  Widget _caffeineView() {
    final graphList = _cafGraph; // 7 日（古 → 新）
    final recordList = _caf; // 全件
    const limit = 400;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                graphList.isEmpty
                    ? const Center(child: Text('グラフデータなし'))
                    : BarChart(
                      BarChartData(
                        maxY: 1000,
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        // タッチしたときの挙動
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor:
                                (BarChartGroupData group) => Colors.blueGrey,
                            getTooltipItem:
                                (group, _, rod, __) => BarTooltipItem(
                                  _fmtMg(graphList[group.x].mg), // 例: 120mg
                                  const TextStyle(color: Colors.white),
                                ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= graphList.length) {
                                  return const SizedBox.shrink();
                                }
                                final d = graphList[i].date; // ★ ここだけ変更
                                return Text('${d.month}/${d.day}');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < graphList.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: graphList[i].mg.toDouble(), // ★ ここだけ変更
                                  width: 18,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
          ),
        ),
        Expanded(
          child:
              recordList.isEmpty
                  ? const Center(child: Text('カフェインデータがありません'))
                  : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: recordList.length,
                    itemBuilder: (_, i) {
                      final d = recordList[i];
                      final mgValue = d.mg;
                      return _RecordTile(
                        date: d.date,
                        value: '${mgValue}mg',
                        highlight: mgValue >= limit,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                  ),
        ),
      ],
    );
  }

  // データ変更時のコールバック
  void _onDataChanged(Map<String, dynamic> payload) {
    print('History: データが変更されました');
    _loadData(); // データを再読み込み
  }

  @override
  void dispose() {
    // コールバックをクリア
    RealtimeService.setCaffeineCallback((_) {});
    RealtimeService.setSleepCallback((_) {});
    super.dispose();
  }
}

/* ---------------- ヘルパークラス ---------------- */

class _Sleep {
  final DateTime date;
  final Duration dur;
  _Sleep(this.date, this.dur);
}

class _Caf {
  final DateTime date;
  final int mg;
  _Caf(this.date, this.mg);
}

/* ---------------- 共通タイル ---------------- */

class _RecordTile extends StatelessWidget {
  final DateTime date;
  final String value;
  final bool highlight;
  const _RecordTile({
    required this.date,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? Colors.red.shade50 : Colors.grey.shade200;
    final txt = highlight ? Colors.red : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('${date.year}/${_pad(date.month)}/${_pad(date.day)}'),
          ),
          Text(
            value,
            style: TextStyle(
              color: txt,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
