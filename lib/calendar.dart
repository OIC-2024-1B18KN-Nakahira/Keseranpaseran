import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

enum CalendarViewType { month, week, day }

class Calendar extends ConsumerStatefulWidget {
  const Calendar({super.key});

  @override
  ConsumerState<Calendar> createState() => _CalendarState();
}

class _CalendarState extends ConsumerState<Calendar> {
  late EventsController controller;
  bool _isLoading = false;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Map<String, dynamic>>> _eventsByDate = {};
  CalendarViewType _currentView = CalendarViewType.month;

  // イベントIDとEventオブジェクトのマッピング
  Map<String, Event> _eventIdMap = {};

  // 日付ごとのカフェイン摂取量と睡眠時間のキャッシュ
  Map<String, double> _caffeinByDate = {};
  Map<String, double?> _sleepByDate = {};

  // 日付ごとのスタンプデータ
  Map<String, List<Map<String, dynamic>>> _stampsByDate = {};

  // 利用可能なスタンプ（絵文字）リスト
  static const List<String> _availableStamps = [
    '😊', '😴', '☕', '🎉', '💪', '🏃', '📚', '💼',
    '🎵', '🍽️', '🌟', '❤️', '🔥', '✨', '🎯', '✅',
    '😢', '😤', '🤒', '💊', '🏥', '🍀', '🌈', '🌙',
    '☀️', '🌧️', '❄️', '🌸', '🍎', '🥗', '🍰', '🍺',
  ];

  @override
  void initState() {
    super.initState();
    controller = EventsController();
    _loadCalendarEvents();
    _loadCalendarStamps();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // 予定データを読み込む
  Future<void> _loadCalendarEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        return;
      }

      // 表示月の前後1ヶ月分のデータを取得
      final startDate = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      final endDate = DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0);

      final startDateString = _formatDate(startDate);
      final endDateString = _formatDate(endDate);

      final events = await supabase
          .from('calendar_events')
          .select()
          .eq('user_id', currentUser.id)
          .gte('event_date', startDateString)
          .lte('event_date', endDateString)
          .order('event_date')
          .order('start_time');

      // 日付ごとにグループ化
      _eventsByDate = {};
      for (final event in events) {
        final dateKey = event['event_date'] as String;
        _eventsByDate[dateKey] ??= [];
        _eventsByDate[dateKey]!.add(event);
      }

      // EventsControllerにイベントを追加
      _eventIdMap.clear();
      controller.updateCalendarData((calendarData) {
        calendarData.dayEvents.clear();

        for (final entry in _eventsByDate.entries) {
          final dateParts = entry.key.split('-');
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);

          for (final eventData in entry.value) {
            // 開始・終了時間を取得
            int startHour = 9, startMinute = 0;
            int endHour = 10, endMinute = 0;

            if (eventData['start_time'] != null) {
              final parts = (eventData['start_time'] as String).split(':');
              startHour = int.parse(parts[0]);
              startMinute = int.parse(parts[1]);
            }
            if (eventData['end_time'] != null) {
              final parts = (eventData['end_time'] as String).split(':');
              endHour = int.parse(parts[0]);
              endMinute = int.parse(parts[1]);
            }

            final color = _parseColor(eventData['color'] as String?);
            final event = Event(
              startTime: DateTime(year, month, day, startHour, startMinute),
              endTime: DateTime(year, month, day, endHour, endMinute),
              title: eventData['title'] ?? '',
              color: color,
            );
            calendarData.addEvents([event]);

            // イベントIDとEventオブジェクトをマッピング
            _eventIdMap[eventData['id']] = event;
          }
        }
      });
    } catch (error) {
      print('予定データ取得エラー: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // スタンプデータを読み込む
  Future<void> _loadCalendarStamps() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        return;
      }

      // 表示月の前後1ヶ月分のデータを取得
      final startDate = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      final endDate = DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0);

      final startDateString = _formatDate(startDate);
      final endDateString = _formatDate(endDate);

      final stamps = await supabase
          .from('calendar_stamps')
          .select()
          .eq('user_id', currentUser.id)
          .gte('stamp_date', startDateString)
          .lte('stamp_date', endDateString)
          .order('created_at');

      // 日付ごとにグループ化
      _stampsByDate = {};
      for (final stamp in stamps) {
        final dateKey = stamp['stamp_date'] as String;
        _stampsByDate[dateKey] ??= [];
        _stampsByDate[dateKey]!.add(stamp);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      print('スタンプデータ取得エラー: $error');
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  // カフェイン計算関数
  double _calculateCaffeineFromRecord(String drinkType, int amountMl) {
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

  // 特定の日のカフェイン摂取量と睡眠時間を取得
  Future<Map<String, dynamic>> _loadDayHealthData(DateTime day) async {
    final dateKey = _formatDate(day);
    double totalCaffeine = 0.0;
    double? sleepHours;

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        return {'caffeine': 0.0, 'sleep': null};
      }

      // カフェイン摂取量を取得
      try {
        final nextDay = DateTime(day.year, day.month, day.day + 1);
        final caffeineResponse = await supabase
            .from('caffeine_records')
            .select('amount_ml, drink_type')
            .eq('user_id', currentUser.id)
            .gte('recorded_at', '${dateKey}T00:00:00.000Z')
            .lt('recorded_at', '${_formatDate(nextDay)}T00:00:00.000Z');

        for (final record in caffeineResponse) {
          final amountMl = record['amount_ml'] as int? ?? 0;
          final drinkType = record['drink_type'] as String? ?? 'コーヒー';
          totalCaffeine += _calculateCaffeineFromRecord(drinkType, amountMl);
        }
      } catch (e) {
        print('カフェインデータ取得エラー: $e');
      }

      // 睡眠時間を取得
      try {
        final sleepResponse = await supabase
            .from('sleep_records')
            .select('sleep_duration_minutes')
            .eq('user_id', currentUser.id)
            .eq('record_date', dateKey);

        if (sleepResponse.isNotEmpty) {
          int totalSleepMinutes = 0;
          for (var record in sleepResponse) {
            final sleepMinutes = record['sleep_duration_minutes'] as int? ?? 0;
            totalSleepMinutes += sleepMinutes;
          }
          sleepHours = totalSleepMinutes / 60.0;
        }
      } catch (e) {
        print('睡眠データ取得エラー: $e');
      }
    } catch (e) {
      print('データ取得エラー: $e');
    }

    // キャッシュに保存
    _caffeinByDate[dateKey] = totalCaffeine;
    _sleepByDate[dateKey] = sleepHours;

    return {'caffeine': totalCaffeine, 'sleep': sleepHours};
  }

  // ドラムロール形式の時間選択ダイアログを表示
  Future<TimeOfDay?> _showCupertinoTimePicker({
    required BuildContext context,
    TimeOfDay? initialTime,
  }) async {
    TimeOfDay? selectedTime;
    final initial = initialTime ?? TimeOfDay.now();
    // TimeOfDayをDateTimeに変換（CupertinoDatePickerはDateTimeを使用）
    DateTime tempDateTime = DateTime(
      2000, 1, 1,
      initial.hour,
      initial.minute,
    );

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // ヘッダー部分（キャンセル・完了ボタン）
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: const Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('キャンセル'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('完了'),
                    onPressed: () {
                      selectedTime = TimeOfDay(
                        hour: tempDateTime.hour,
                        minute: tempDateTime.minute,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // ドラムロール部分
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: tempDateTime,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDateTime) {
                  tempDateTime = newDateTime;
                },
              ),
            ),
          ],
        ),
      ),
    );

    return selectedTime;
  }

  // ドラッグ&ドロップでイベントを移動
  Future<void> _moveEvent(Event oldEvent, DateTime newStart, DateTime newEnd) async {
    // データベース内の対応するイベントを探す
    String? eventId;
    for (final entry in _eventIdMap.entries) {
      if (entry.value == oldEvent) {
        eventId = entry.key;
        break;
      }
    }

    if (eventId == null) {
      // イベントIDが見つからない場合、タイトルと元の時間で検索
      for (final dateEvents in _eventsByDate.values) {
        for (final eventData in dateEvents) {
          if (eventData['title'] == oldEvent.title) {
            eventId = eventData['id'];
            break;
          }
        }
        if (eventId != null) break;
      }
    }

    if (eventId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('イベントが見つかりませんでした')),
        );
      }
      return;
    }

    try {
      // コントローラーを更新
      controller.updateCalendarData((calendarData) {
        calendarData.updateEvent(
          oldEvent: oldEvent,
          newEvent: oldEvent.copyWith(startTime: newStart, endTime: newEnd),
        );
      });

      // データベースを更新
      await supabase.from('calendar_events').update({
        'event_date': _formatDate(newStart),
        'start_time':
            '${newStart.hour.toString().padLeft(2, '0')}:${newStart.minute.toString().padLeft(2, '0')}:00',
        'end_time':
            '${newEnd.hour.toString().padLeft(2, '0')}:${newEnd.minute.toString().padLeft(2, '0')}:00',
      }).eq('id', eventId);

      // データを再読み込み
      await _loadCalendarEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予定を移動しました')),
        );
      }
    } catch (error) {
      print('予定移動エラー: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('予定の移動に失敗しました: $error')),
        );
      }
      // エラー時はデータを再読み込みして元に戻す
      await _loadCalendarEvents();
    }
  }

  // スタンプ追加ダイアログ
  Future<void> _showAddStampDialog(DateTime date) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('スタンプを追加 (${_formatDate(date)})'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _availableStamps.length,
            itemBuilder: (context, index) {
              final emoji = _availableStamps[index];
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _addStamp(date, emoji);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  // スタンプをデータベースに追加
  Future<void> _addStamp(DateTime date, String emoji) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase.from('calendar_stamps').insert({
        'user_id': currentUser.id,
        'stamp_date': _formatDate(date),
        'emoji': emoji,
      });

      await _loadCalendarStamps();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('スタンプ $emoji を追加しました')),
        );
      }
    } catch (error) {
      print('スタンプ追加エラー: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('スタンプの追加に失敗しました: $error')),
        );
      }
    }
  }

  // スタンプを削除
  Future<void> _deleteStamp(String id) async {
    try {
      await supabase.from('calendar_stamps').delete().eq('id', id);
      await _loadCalendarStamps();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('スタンプを削除しました')),
        );
      }
    } catch (error) {
      print('スタンプ削除エラー: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('スタンプの削除に失敗しました: $error')),
        );
      }
    }
  }

  // 予定追加ダイアログ
  Future<void> _showAddEventDialog([DateTime? selectedDate]) async {
    final date = selectedDate ?? _selectedDay ?? DateTime.now();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    Color selectedColor = Colors.blue;

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('予定を追加 (${_formatDate(date)})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル *',
                    hintText: '予定のタイトル',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '詳細',
                    hintText: '予定の詳細（任意）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(startTime != null
                            ? '開始: ${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                            : '開始時間'),
                        onPressed: () async {
                          final time = await _showCupertinoTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (time != null) {
                            setDialogState(() {
                              startTime = time;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(endTime != null
                            ? '終了: ${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                            : '終了時間'),
                        onPressed: () async {
                          final time = await _showCupertinoTimePicker(
                            context: context,
                            initialTime: endTime ?? startTime,
                          );
                          if (time != null) {
                            setDialogState(() {
                              endTime = time;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('色'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイトルを入力してください')),
                  );
                  return;
                }

                await _addEvent(
                  date: date,
                  title: titleController.text,
                  description: descriptionController.text,
                  startTime: startTime,
                  endTime: endTime,
                  color: selectedColor,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  // 予定をデータベースに追加
  Future<void> _addEvent({
    required DateTime date,
    required String title,
    String? description,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required Color color,
  }) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final colorHex = '#${color.value.toRadixString(16).substring(2)}';

      await supabase.from('calendar_events').insert({
        'user_id': currentUser.id,
        'title': title,
        'description': description,
        'event_date': _formatDate(date),
        'start_time': startTime != null
            ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00'
            : null,
        'end_time': endTime != null
            ? '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00'
            : null,
        'color': colorHex,
      });

      await _loadCalendarEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予定を追加しました')),
        );
      }
    } catch (error) {
      print('予定追加エラー: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('予定の追加に失敗しました: $error')),
        );
      }
    }
  }

  // 日付の予定一覧を表示
  void _showEventsForDay(DateTime day) {
    final dateKey = _formatDate(day);
    final events = _eventsByDate[dateKey] ?? [];
    final stamps = _stampsByDate[dateKey] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day.year}年${day.month}月${day.day}日の予定',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // カフェイン摂取量と睡眠時間の表示
                          FutureBuilder<Map<String, dynamic>>(
                            future: _loadDayHealthData(day),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  '読み込み中...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                );
                              }

                              final caffeine = snapshot.data?['caffeine'] as double? ?? 0.0;
                              final sleep = snapshot.data?['sleep'] as double?;
                              final sleepText = sleep != null
                                  ? '${sleep.toStringAsFixed(1)}時間'
                                  : '未記録';

                              return Text(
                                'カフェイン: ${caffeine.round()}mg / 睡眠時間: $sleepText',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // スタンプ追加ボタン
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      tooltip: 'スタンプを追加',
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddStampDialog(day);
                      },
                    ),
                    // 予定追加ボタン
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: '予定を追加',
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEventDialog(day);
                      },
                    ),
                  ],
                ),
              ),
              // スタンプセクション
              if (stamps.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'スタンプ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: stamps.map((stamp) {
                          return GestureDetector(
                            onLongPress: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('スタンプを削除'),
                                  content: Text('スタンプ ${stamp['emoji']} を削除しますか？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('削除'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                Navigator.pop(context);
                                await _deleteStamp(stamp['id']);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                stamp['emoji'] ?? '',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: events.isEmpty
                    ? const Center(
                        child: Text(
                          '予定はありません',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final color = _parseColor(event['color'] as String?);
                          final startTime = event['start_time'] as String?;
                          final endTime = event['end_time'] as String?;

                          String timeText = '';
                          if (startTime != null) {
                            timeText = startTime.substring(0, 5);
                            if (endTime != null) {
                              timeText += ' - ${endTime.substring(0, 5)}';
                            }
                          }

                          return ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(event['title'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (timeText.isNotEmpty) Text(timeText),
                                if (event['description'] != null &&
                                    (event['description'] as String).isNotEmpty)
                                  Text(
                                    event['description'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('編集'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('削除', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.pop(context);
                                  await _showEditEventDialog(event);
                                } else if (value == 'delete') {
                                  Navigator.pop(context);
                                  await _deleteEvent(event['id']);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 予定編集ダイアログ
  Future<void> _showEditEventDialog(Map<String, dynamic> event) async {
    final titleController = TextEditingController(text: event['title']);
    final descriptionController = TextEditingController(text: event['description'] ?? '');

    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if (event['start_time'] != null) {
      final parts = (event['start_time'] as String).split(':');
      startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (event['end_time'] != null) {
      final parts = (event['end_time'] as String).split(':');
      endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    Color selectedColor = _parseColor(event['color'] as String?);

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('予定を編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '詳細',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(startTime != null
                            ? '開始: ${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                            : '開始時間'),
                        onPressed: () async {
                          final time = await _showCupertinoTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (time != null) {
                            setDialogState(() {
                              startTime = time;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(endTime != null
                            ? '終了: ${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                            : '終了時間'),
                        onPressed: () async {
                          final time = await _showCupertinoTimePicker(
                            context: context,
                            initialTime: endTime ?? startTime,
                          );
                          if (time != null) {
                            setDialogState(() {
                              endTime = time;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('色'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイトルを入力してください')),
                  );
                  return;
                }

                await _updateEvent(
                  id: event['id'],
                  title: titleController.text,
                  description: descriptionController.text,
                  startTime: startTime,
                  endTime: endTime,
                  color: selectedColor,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('更新'),
            ),
          ],
        ),
      ),
    );
  }

  // 予定を更新
  Future<void> _updateEvent({
    required String id,
    required String title,
    String? description,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required Color color,
  }) async {
    try {
      final colorHex = '#${color.value.toRadixString(16).substring(2)}';

      await supabase.from('calendar_events').update({
        'title': title,
        'description': description,
        'start_time': startTime != null
            ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00'
            : null,
        'end_time': endTime != null
            ? '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00'
            : null,
        'color': colorHex,
      }).eq('id', id);

      await _loadCalendarEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予定を更新しました')),
        );
      }
    } catch (error) {
      print('予定更新エラー: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('予定の更新に失敗しました: $error')),
        );
      }
    }
  }

  // 予定を削除
  Future<void> _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定を削除'),
        content: const Text('この予定を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('calendar_events').delete().eq('id', id);
      await _loadCalendarEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予定を削除しました')),
        );
      }
    } catch (error) {
      print('予定削除エラー: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('予定の削除に失敗しました: $error')),
        );
      }
    }
  }

  // ドラッグ可能なイベントウィジェットを構築
  Widget _buildDraggableEvent(
    Event event,
    double height,
    double width,
    double heightPerMinute,
  ) {
    return DraggableEventWidget(
      event: event,
      height: height,
      width: width,
      heightPerMinute: heightPerMinute,
      onDragEnd: (exactStart, exactEnd, roundStart, roundEnd) {
        _moveEvent(event, roundStart, roundEnd);
      },
      child: Container(
        height: height,
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (height > 30)
              Text(
                '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime?.hour.toString().padLeft(2, '0')}:${event.endTime?.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ビュー切り替えプルダウン（SegmentedButton風の見た目）
  Widget _buildViewSwitcher() {
    // ビュータイプと表示名のマッピング
    const viewLabels = {
      CalendarViewType.month: '月',
      CalendarViewType.week: '週',
      CalendarViewType.day: '日',
    };

    const viewIcons = {
      CalendarViewType.month: Icons.calendar_month,
      CalendarViewType.week: Icons.view_week,
      CalendarViewType.day: Icons.view_day,
    };

    return PopupMenuButton<CalendarViewType>(
      initialValue: _currentView,
      onSelected: (CalendarViewType newView) {
        setState(() {
          _currentView = newView;
        });
      },
      itemBuilder: (context) => CalendarViewType.values.map((viewType) {
        final isSelected = viewType == _currentView;
        return PopupMenuItem<CalendarViewType>(
          value: viewType,
          child: Row(
            children: [
              Icon(
                viewIcons[viewType],
                size: 20,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                viewLabels[viewType]!,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              viewIcons[_currentView],
              size: 18,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              viewLabels[_currentView]!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  // 日本語の月名リスト
  static const List<String> _japaneseMonthNames = [
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月',
  ];

  // 日本語の曜日名リスト（日曜日始まり）
  static const List<String> _japaneseWeekDays = [
    '日', '月', '火', '水', '木', '金', '土',
  ];

  // 曜日番号から日本語曜日名を取得
  String _getJapaneseWeekDay(int weekday) {
    // DateTime.weekday は 1=月曜日 ～ 7=日曜日
    // リストは日曜日始まりなので変換
    final index = weekday % 7;
    return _japaneseWeekDays[index];
  }

  // 月表示カレンダー
  Widget _buildMonthView() {
    return EventsMonths(
      controller: controller,
      onMonthChange: (month) {
        setState(() {
          _focusedMonth = month;
        });
        _loadCalendarEvents();
        _loadCalendarStamps();
      },
      weekParam: WeekParam(
        headerDayBuilder: (dayOfWeek) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _japaneseWeekDays[dayOfWeek % 7],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: dayOfWeek == DateTime.sunday
                    ? Colors.red
                    : dayOfWeek == DateTime.saturday
                        ? Colors.blue
                        : Colors.black,
              ),
            ),
          );
        },
      ),
      daysParam: DaysParam(
        onDayTapUp: (day) {
          setState(() {
            _selectedDay = day;
          });
          _showEventsForDay(day);
        },
        dayBuilder: (day, events, isToday, isInMonth) {
          final dateKey = _formatDate(day);
          final stamps = _stampsByDate[dateKey] ?? [];
          final dayEvents = _eventsByDate[dateKey] ?? [];

          final weekDayColor = day.weekday == DateTime.sunday
              ? Colors.red
              : day.weekday == DateTime.saturday
                  ? Colors.blue
                  : Colors.black87;

          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.blue.withOpacity(0.1)
                  : isInMonth
                      ? Colors.white
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: isToday
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 日付番号
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isInMonth ? weekDayColor : Colors.grey,
                    ),
                  ),
                ),
                // スタンプ表示
                if (stamps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Wrap(
                      spacing: 1,
                      runSpacing: 1,
                      children: stamps.take(3).map((stamp) {
                        return Text(
                          stamp['emoji'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
                // イベントインジケーター
                if (dayEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      children: dayEvents.take(3).map((event) {
                        final color = _parseColor(event['color'] as String?);
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 週表示カレンダー（7日表示）
  Widget _buildWeekView() {
    return EventsPlanner(
      controller: controller,
      daysShowed: 7,
      onDayChange: (day) {
        setState(() {
          _focusedMonth = day;
        });
      },
      daysHeaderParam: DaysHeaderParam(
        daysHeaderHeight: 50,
        dayHeaderBuilder: (day, isToday) {
          final weekDayColor = day.weekday == DateTime.sunday
              ? Colors.red
              : day.weekday == DateTime.saturday
                  ? Colors.blue
                  : Colors.black;
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.day}(${_getJapaneseWeekDay(day.weekday)})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: weekDayColor,
                    ),
                  ),
                  
                ],
              ),
            ),
          );
        },
      ),
      dayParam: DayParam(
        onSlotTap: (slot, start, end) {
          _showAddEventDialog(start);
        },
        dayEventBuilder: (event, height, width, heightPerMinute) {
          return _buildDraggableEvent(event, height, width, heightPerMinute);
        },
      ),
    );
  }

  // 日表示カレンダー（1日表示）
  Widget _buildDayView() {
    return EventsPlanner(
      controller: controller,
      daysShowed: 1,
      onDayChange: (day) {
        setState(() {
          _focusedMonth = day;
        });
      },
      daysHeaderParam: DaysHeaderParam(
        dayHeaderBuilder: (day, isToday) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${day.day}(${_getJapaneseWeekDay(day.weekday)})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: day.weekday == DateTime.sunday
                    ? Colors.red
                    : day.weekday == DateTime.saturday
                        ? Colors.blue
                        : Colors.black,
              ),
            ),
          );
        },
      ),
      dayParam: DayParam(
        onSlotTap: (slot, start, end) {
          _showAddEventDialog(start);
        },
        dayEventBuilder: (event, height, width, heightPerMinute) {
          return _buildDraggableEvent(event, height, width, heightPerMinute);
        },
      ),
    );
  }

  // 現在のビューを取得
  Widget _buildCurrentView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentView) {
      case CalendarViewType.month:
        return _buildMonthView();
      case CalendarViewType.week:
        return _buildWeekView();
      case CalendarViewType.day:
        return _buildDayView();
    }
  }

  // 現在表示中の月を日本語で取得
  String _getJapaneseMonthTitle() {
    return '${_focusedMonth.year}年${_japaneseMonthNames[_focusedMonth.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getJapaneseMonthTitle()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildViewSwitcher(),
          ),
        ),
      ),
      drawer: const Drawer(),
      body: _buildCurrentView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ドラッグ可能なイベントウィジェット
///
/// heightPerMinute: 1分あたりの高さ（ピクセル）
/// - カレンダー上でイベントの位置や高さを計算するために使用
/// - ドラッグ移動量を時間に変換する際にも使用
class DraggableEventWidget extends StatefulWidget {
  final Event event;
  final double height;
  final double width;
  final double heightPerMinute;
  final Function(DateTime exactStart, DateTime exactEnd, DateTime roundStart, DateTime roundEnd) onDragEnd;
  final Widget child;

  const DraggableEventWidget({
    super.key,
    required this.event,
    required this.height,
    required this.width,
    required this.heightPerMinute,
    required this.onDragEnd,
    required this.child,
  });

  @override
  State<DraggableEventWidget> createState() => _DraggableEventWidgetState();
}

class _DraggableEventWidgetState extends State<DraggableEventWidget> {
  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragOffset = Offset.zero;
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      onVerticalDragEnd: (details) {
        // startTime/endTimeがnullの場合は何もしない
        final startTime = widget.event.startTime;
        final endTime = widget.event.endTime;
        if (endTime == null) {
          setState(() {
            _dragOffset = Offset.zero;
          });
          return;
        }

        // ドラッグ距離から時間の変化を計算（ピクセル ÷ 1分あたりのピクセル = 分）
        final deltaMinutes = (_dragOffset.dy / widget.heightPerMinute).round();

        // 新しい開始・終了時間を計算
        final newStart = startTime.add(Duration(minutes: deltaMinutes));
        final newEnd = endTime.add(Duration(minutes: deltaMinutes));

        // 15分単位に丸めた時間も計算
        final roundedStart = _roundToNearestMinutes(newStart, 15);
        final roundedEnd = _roundToNearestMinutes(newEnd, 15);

        widget.onDragEnd(newStart, newEnd, roundedStart, roundedEnd);

        setState(() {
          _dragOffset = Offset.zero;
        });
      },
      child: Transform.translate(
        offset: _dragOffset,
        child: widget.child,
      ),
    );
  }

  /// 指定した分数単位に時間を丸める
  DateTime _roundToNearestMinutes(DateTime dt, int minutes) {
    final totalMinutes = dt.hour * 60 + dt.minute;
    final roundedMinutes = ((totalMinutes / minutes).round() * minutes);
    final newHour = (roundedMinutes ~/ 60) % 24;
    final newMinute = roundedMinutes % 60;
    return DateTime(dt.year, dt.month, dt.day, newHour, newMinute);
  }
}
