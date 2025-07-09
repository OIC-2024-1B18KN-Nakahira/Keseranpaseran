import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sleep_record.dart';
import 'caffeine_record.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  /// 0 = Sleep / 1 = Caffeine
  int _mode = 0;

  /* ---------------- ダミーデータ ---------------- */

  static final List<SleepRecord> _sleep = [
    SleepRecord(date: DateTime(2025, 6, 11), duration: const Duration(hours: 7, minutes: 40)),
    SleepRecord(date: DateTime(2025, 6, 12), duration: const Duration(hours: 7, minutes: 40)),
    SleepRecord(date: DateTime(2025, 6, 13), duration: const Duration(hours: 7, minutes: 40)),
    SleepRecord(date: DateTime(2025, 6, 14), duration: const Duration(hours: 6, minutes: 55)),
    SleepRecord(date: DateTime(2025, 6, 15), duration: const Duration(hours: 8, minutes: 10)),
    SleepRecord(date: DateTime(2025, 6, 16), duration: const Duration(hours: 5, minutes: 45)),
    SleepRecord(date: DateTime(2025, 6, 17), duration: const Duration(hours: 9, minutes: 5)),
    SleepRecord(date: DateTime(2025, 6, 19), duration: const Duration(hours: 8, minutes: 30)),
  ];

  static final List<CaffeineRecord> _caf = [
    CaffeineRecord(date: DateTime(2025, 6, 11), mg: 200),
    CaffeineRecord(date: DateTime(2025, 6, 12), mg: 150),
    CaffeineRecord(date: DateTime(2025, 6, 13), mg: 300),
    CaffeineRecord(date: DateTime(2025, 6, 14), mg: 180),
    CaffeineRecord(date: DateTime(2025, 6, 15), mg: 450),
    CaffeineRecord(date: DateTime(2025, 6, 16), mg: 500),
    CaffeineRecord(date: DateTime(2025, 6, 17), mg: 120),
    CaffeineRecord(date: DateTime(2025, 6, 19), mg: 420),
  ];

  /* ---------- 共通ヘルパー ---------- */

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  DateTime _toDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDur(Duration d) => '${d.inHours}h${d.inMinutes.remainder(60)}m';

  String _fmtMg(int mg) => '${mg}mg';

  /* ---------- グラフ専用 Getter（最新から 7 日固定） ---------- */

  List<SleepRecord> get _sleepGraph {
    if (_sleep.isEmpty) return [];
    final latestDay = _toDay(
      _sleep.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date,
    );

    final map = {for (var e in _sleep) _key(e.date): e};

    // latestDay -6 〜 latestDay の 7 日分（古 → 新）
    return List.generate(7, (i) {
      final d = latestDay.subtract(Duration(days: 6 - i));
      return map[_key(d)] ?? SleepRecord(date: d, duration: Duration.zero);
    });
  }

  List<CaffeineRecord> get _cafGraph {
    if (_caf.isEmpty) return [];
    final latestDay = _toDay(
      _caf.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date,
    );

    final map = {for (var e in _caf) _key(e.date): e};

    return List.generate(7, (i) {
      final d = latestDay.subtract(Duration(days: 6 - i));
      return map[_key(d)] ?? CaffeineRecord(date: d, mg: 0);
    });
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
        centerTitle: true,
      ),
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
                      child: Text('睡眠')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('カフェイン')),
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
    final graphList = _sleepGraph;
    final recordList = _sleep;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: graphList.isEmpty
                ? const Center(child: Text('グラフデータなし'))
                : LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 24,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.blueGrey,
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      return LineTooltipItem(
                        _fmtDur(graphList[idx].duration),
                        const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
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
                        final d = graphList[i].date;
                        return Text('${d.month}/${d.day}',
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
                          Colors.blue.withAlpha(77),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    spots: [
                      for (var i = 0; i < graphList.length; i++)
                        FlSpot(
                          i.toDouble(),
                          graphList[i].duration.inMinutes / 60.0,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: recordList.length,
            itemBuilder: (_, i) {
              final d = recordList[i];
              final h = d.duration.inHours;
              final m = d.duration.inMinutes.remainder(60);
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
    final graphList = _cafGraph;
    final recordList = _caf;
    const limit = 400;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: graphList.isEmpty
                ? const Center(child: Text('グラフデータなし'))
                : BarChart(
              BarChartData(
                maxY: 1000,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      _fmtMg(graphList[group.x].mg),
                      const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= graphList.length) return const SizedBox.shrink();
                        final d = graphList[i].date;
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
                          toY: graphList[i].mg.toDouble(),
                          width: 18,
                          color: Colors.grey.shade400,
                        )
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: recordList.length,
            itemBuilder: (_, i) => _RecordTile(
              date: recordList[i].date,
              value: '${recordList[i].mg}mg',
              highlight: recordList[i].mg > limit,
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
          ),
        ),
      ],
    );
  }
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
              child: Text(
                  '${date.year}/${_pad(date.month)}/${_pad(date.day)}')),
          Text(
            value,
            style: TextStyle(
                color: txt, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}