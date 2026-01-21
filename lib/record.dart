import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widget/appbar_widget.dart';
import 'provider.dart' as provider;

final supabase = Supabase.instance.client;

class Record extends ConsumerStatefulWidget {
  const Record({super.key});

  @override
  ConsumerState<Record> createState() => _RecordState();
}

class _RecordState extends ConsumerState<Record> {
  DateTime selectedDateTime = DateTime.now();
  String selectedDrink = "コーヒー";
  int selectedAmount = 200;
  TimeOfDay? bedtime;
  TimeOfDay? wakeTime;
  bool _hasCaffeineDataChanged = false;

  double calculateCaffeineAmount() {
    switch (selectedDrink) {
      case "コーラ":
        return (selectedAmount / 350.0) * 40.0;
      case "コーヒー":
      case "紅茶":
        return (selectedAmount / 200.0) * 60.0;
      case "栄養ドリンク":
      case "エナジードリンク":
        return (selectedAmount / 100.0) * 150.0;
      case "緑茶":
        return (selectedAmount / 200.0) * 20.0;
      case "ウーロン茶":
        return (selectedAmount / 200.0) * 20.0;
      case "ココア":
        return (selectedAmount / 200.0) * 5.0;
      case "その他":
        return (selectedAmount / 200.0) * 60.0;
      default:
        return 0.0;
    }
  }

  // ドラムロール形式の時間選択ダイアログを表示
  Future<TimeOfDay?> _showCupertinoTimePicker({
    required BuildContext context,
    TimeOfDay? initialTime,
  }) async {
    TimeOfDay? selectedTime;
    final initial = initialTime ?? TimeOfDay.now();
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

  void resetInputs() {
    setState(() {
      selectedDateTime = DateTime.now();
      selectedDrink = "コーヒー";
      selectedAmount = 200;
      bedtime = null;
      wakeTime = null;
      _hasCaffeineDataChanged = false;
    });
  }

  Future<void> saveRecord() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ログインが必要です')));
        return;
      }

      if (!_hasCaffeineDataChanged && (bedtime == null || wakeTime == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カフェインまたは睡眠時間のいずれかを記録してください'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      double caffeineAmount = 0.0;

      if (_hasCaffeineDataChanged) {
        caffeineAmount = calculateCaffeineAmount();

        final caffeineData = {
          'user_id': user.id,
          'recorded_at': selectedDateTime.toIso8601String(),
          'drink_type': selectedDrink,
          'amount_ml': selectedAmount,
        };

        await supabase.from('caffeine_records').insert(caffeineData).select();
      }

      if (bedtime != null && wakeTime != null) {
        final today = DateTime.now();
        final recordDate = today.toIso8601String().split('T')[0];

        try {
          await supabase
              .from('sleep_records')
              .delete()
              .eq('user_id', user.id)
              .eq('record_date', recordDate);
        } catch (_) {}

        final bedDateTime = DateTime(
          today.year,
          today.month,
          today.day,
          bedtime!.hour,
          bedtime!.minute,
        );
        final wakeDateTime = DateTime(
          today.year,
          today.month,
          today.day,
          wakeTime!.hour,
          wakeTime!.minute,
        );

        final adjustedWakeTime = wakeDateTime.isBefore(bedDateTime)
            ? wakeDateTime.add(Duration(days: 1))
            : wakeDateTime;

        final duration = adjustedWakeTime.difference(bedDateTime);

        final sleepData = {
          'user_id': user.id,
          'record_date': recordDate,
          'bedtime':
              '${bedtime!.hour.toString().padLeft(2, '0')}:${bedtime!.minute.toString().padLeft(2, '0')}:00',
          'wake_time':
              '${wakeTime!.hour.toString().padLeft(2, '0')}:${wakeTime!.minute.toString().padLeft(2, '0')}:00',
          'sleep_duration_minutes': duration.inMinutes,
        };

        await supabase.from('sleep_records').insert(sleepData).select();
      }

      provider.notifyDataUpdate(ref);
      await Future.delayed(Duration(milliseconds: 300));

      resetInputs();

      String message = '記録を保存しました';
      if (_hasCaffeineDataChanged && bedtime != null && wakeTime != null) {
        message = '記録を保存しました（カフェイン: ${caffeineAmount.round()}mg、睡眠時間も保存）';
      } else if (_hasCaffeineDataChanged) {
        message = '記録を保存しました（カフェイン: ${caffeineAmount.round()}mg）';
      } else if (bedtime != null && wakeTime != null) {
        message = '記録を保存しました（睡眠時間のみ）';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 3)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存に失敗しました: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCaffeine = calculateCaffeineAmount();

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: CalendarIcon(),
        ),
        actions: [AppTitle()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("記録", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '予想カフェイン量: ${currentCaffeine.round()}mg',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "カフェインをとった時間",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            final TimeOfDay? time = await _showCupertinoTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                selectedDateTime = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  time.hour,
                                  time.minute,
                                );
                                _hasCaffeineDataChanged = true;
                              });
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          child: Text(
                            "${selectedDateTime.year}年${selectedDateTime.month}月${selectedDateTime.day}日　${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Text("飲み物の種類",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Meun(
                key: ValueKey(selectedDrink),
                onDrinkChanged: (drink) {
                  setState(() {
                    selectedDrink = drink;
                    _hasCaffeineDataChanged = true;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: DrinkButton(
                      key: ValueKey(selectedAmount),
                      onAmountChanged: (amount) {
                        setState(() {
                          selectedAmount = amount;
                          _hasCaffeineDataChanged = true;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "本日の睡眠時間",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 1),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: TimeButton(
                          bedtime: bedtime,
                          wakeTime: wakeTime,
                          onBedtimeChanged: (time) {
                            setState(() {
                              bedtime = time;
                            });
                          },
                          onWakeTimeChanged: (time) {
                            setState(() {
                              wakeTime = time;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(child: RecoedButton(onPressed: saveRecord)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Meun extends StatefulWidget {
  final Function(String) onDrinkChanged;

  const Meun({super.key, required this.onDrinkChanged});

  @override
  State<Meun> createState() => _MeunState();
}

class _MeunState extends State<Meun> {
  String _selectedDrink = "コーヒー";

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 160),
        child: DropdownButtonFormField(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.only(left: 10),
            border: OutlineInputBorder(),
          ),
          value: _selectedDrink,
          items: [
            DropdownMenuItem(
              value: "コーヒー",
              child: Text(
                "コーヒー (60mg/200ml)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "紅茶",
              child: Text(
                "紅茶 (60mg/200ml)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "コーラ",
              child: Text(
                "コーラ (40mg/350ml)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "栄養ドリンク",
              child: Text(
                "栄養ドリンク (150mg/100ml)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "エナジードリンク",
              child: Text(
                "エナジードリンク (150mg/100ml)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "緑茶",
              child: Text(
                "緑茶 (20mg/200ml)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "ウーロン茶",
              child: Text(
                "ウーロン茶 (20mg/200ml)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "ココア",
              child: Text(
                "ココア (5mg/200ml)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "その他",
              child: Text(
                "その他",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _selectedDrink = newValue!;
            });
            widget.onDrinkChanged(newValue!);
          },
        ),
      ),
    );
  }
}

class DrinkButton extends StatefulWidget {
  final Function(int) onAmountChanged;

  const DrinkButton({Key? key, required this.onAmountChanged})
      : super(key: key);

  @override
  _DrinkButtonState createState() => _DrinkButtonState();
}

class _DrinkButtonState extends State<DrinkButton> {
  int selectedIndex = 0;

  Widget drinkCupButton(
    int index,
    String label,
    String imagePath,
    String volume,
    int amountMl,
  ) {
    final bool isSelected = selectedIndex == index;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 150,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.orange,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Image.asset(imagePath, width: 50, height: 50)],
              ),
              Text(volume),
            ],
          ),
        ),
        SizedBox(
          width: 100,
          height: 150,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                widget.onAmountChanged(amountMl);
              },
              splashColor: Colors.blue.withOpacity(0.1),
              highlightColor: Colors.transparent,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        drinkCupButton(
          0,
          "1杯",
          "assets/drink_coffee_cup07_american.png",
          "200ml",
          200,
        ),
        drinkCupButton(1, "1缶", "assets/can_coffee.png", "350ml", 350),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: selectedIndex == 2
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.white,
                border: Border.all(
                  color: selectedIndex == 2 ? Colors.blue : Colors.orange,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("1本"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/petbottle_water_full.png",
                        width: 40,
                        height: 50,
                      ),
                    ],
                  ),
                  Text("500ml"),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              height: 150,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    setState(() {
                      selectedIndex = 2;
                    });
                    widget.onAmountChanged(500);
                  },
                  splashColor: Colors.blue.withOpacity(0.1),
                  highlightColor: Colors.transparent,
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TimeButton extends StatelessWidget {
  final TimeOfDay? bedtime;
  final TimeOfDay? wakeTime;
  final Function(TimeOfDay) onBedtimeChanged;
  final Function(TimeOfDay) onWakeTimeChanged;

  const TimeButton({
    super.key,
    required this.bedtime,
    required this.wakeTime,
    required this.onBedtimeChanged,
    required this.onWakeTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFFFA748), width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SizedBox(
                        width: 150,
                        height: 100,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () async {
                              final TimeOfDay? picked = await showCupertinoTimePickerDialog(
                                context: context,
                                initialTime:
                                    bedtime ?? TimeOfDay(hour: 22, minute: 0),
                              );
                              if (picked != null) {
                                onBedtimeChanged(picked);
                              }
                            },
                            splashColor: Colors.blue.withOpacity(0.1),
                            highlightColor: Colors.transparent,
                            child: const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.orange,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      child: Text(
                        "就寝時間",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 50, top: 50),
                    child: Text(
                      bedtime != null
                          ? "${bedtime!.hour.toString().padLeft(2, '0')}:${bedtime!.minute.toString().padLeft(2, '0')}"
                          : "00:00",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFFFA748), width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SizedBox(
                        width: 150,
                        height: 100,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () async {
                              final TimeOfDay? picked = await showCupertinoTimePickerDialog(
                                context: context,
                                initialTime:
                                    wakeTime ?? TimeOfDay(hour: 6, minute: 0),
                              );
                              if (picked != null) {
                                onWakeTimeChanged(picked);
                              }
                            },
                            splashColor: Colors.blue.withOpacity(0.1),
                            highlightColor: Colors.transparent,
                            child: const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.orange,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      child: Text(
                        "起床時間",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 50, top: 50),
                    child: Text(
                      wakeTime != null
                          ? "${wakeTime!.hour.toString().padLeft(2, '0')}:${wakeTime!.minute.toString().padLeft(2, '0')}"
                          : "00:00",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TimeDialog extends StatelessWidget {
  const TimeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const TextField(
        decoration: InputDecoration(
          labelText: '時間を入力',
          border: OutlineInputBorder(),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Text("キャンセル"),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(10),
            color: Colors.orange,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 35, vertical: 10),
              child: Text("保存"),
            ),
          ),
        ),
      ],
    );
  }
}

class RecoedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RecoedButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.orange, width: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onPressed,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Text("記録", style: TextStyle(fontSize: 20, color: Colors.orange)),
      ),
    );
  }
}

// トップレベルのドラムロール時間選択ダイアログ（StatelessWidgetから使用可能）
Future<TimeOfDay?> showCupertinoTimePickerDialog({
  required BuildContext context,
  TimeOfDay? initialTime,
}) async {
  TimeOfDay? selectedTime;
  final initial = initialTime ?? TimeOfDay.now();
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
