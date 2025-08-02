import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//他のファイルで作成したwidgetを使う
import 'widget/appbar_widget.dart'; //追加

final supabase = Supabase.instance.client;

class Record extends StatefulWidget {
  const Record({super.key});

  @override
  State<Record> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  DateTime selectedDateTime = DateTime.now();
  String selectedDrink = "コーヒー";
  int selectedAmount = 200; // 200mlに修正（1杯の標準サイズ）
  TimeOfDay? bedtime;
  TimeOfDay? wakeTime;

  // カフェイン含有量を計算する関数
  double calculateCaffeineAmount() {
    switch (selectedDrink) {
      case "コーラ":
        // コーラ: 40mg/1缶(350ml)
        return (selectedAmount / 350.0) * 40.0;

      case "コーヒー":
      case "紅茶":
        // コーヒー・紅茶: 60mg/1杯(200ml)
        return (selectedAmount / 200.0) * 60.0;

      case "栄養ドリンク":
      case "エナジードリンク":
        // 栄養ドリンク・エナジードリンク: 150mg/1本(100ml)
        return (selectedAmount / 100.0) * 150.0;

      case "緑茶":
        // 緑茶: 20mg/1杯(200ml)
        return (selectedAmount / 200.0) * 20.0;

      case "ウーロン茶":
        // ウーロン茶: 20mg/1杯(200ml)
        return (selectedAmount / 200.0) * 20.0;

      case "ココア":
        // ココア: 5mg/1杯(200ml)
        return (selectedAmount / 200.0) * 5.0;

      case "その他":
        // その他: カフェイン含有量を推定（コーヒーと同等）
        return (selectedAmount / 200.0) * 60.0;

      default:
        return 0.0;
    }
  }

  // 入力をリセットする関数
  void resetInputs() {
    setState(() {
      selectedDateTime = DateTime.now();
      selectedDrink = "コーヒー";
      selectedAmount = 200; // 200mlに修正
      bedtime = null;
      wakeTime = null;
    });
  }

  // データを保存する関数
  Future<void> saveRecord() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ログインが必要です')));
        return;
      }

      // カフェイン量を計算
      final caffeineAmount = calculateCaffeineAmount();

      // カフェイン記録を保存
      await supabase.from('caffeine_records').insert({
        'user_id': user.id,
        'recorded_at': selectedDateTime.toIso8601String(),
        'drink_type': selectedDrink,
        'amount_ml': selectedAmount,
        'caffeine_mg': caffeineAmount.round(), // カフェイン量も保存
      });

      // 睡眠記録を保存（就寝時間と起床時間が両方設定されている場合）
      if (bedtime != null && wakeTime != null) {
        final today = DateTime.now();
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

        // 起床時間が就寝時間より早い場合は翌日と判断
        final adjustedWakeTime =
            wakeDateTime.isBefore(bedDateTime)
                ? wakeDateTime.add(Duration(days: 1))
                : wakeDateTime;

        final duration = adjustedWakeTime.difference(bedDateTime);

        await supabase.from('sleep_records').insert({
          'user_id': user.id,
          'record_date': today.toIso8601String().split('T')[0],
          'bedtime':
              '${bedtime!.hour.toString().padLeft(2, '0')}:${bedtime!.minute.toString().padLeft(2, '0')}:00',
          'wake_time':
              '${wakeTime!.hour.toString().padLeft(2, '0')}:${wakeTime!.minute.toString().padLeft(2, '0')}:00',
          'sleep_duration_minutes': duration.inMinutes,
        });
      }

      // 保存成功後にリセット
      resetInputs();

      // 計算されたカフェイン量を表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('記録を保存しました（カフェイン: ${caffeineAmount.round()}mg）'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 現在のカフェイン量を計算して表示
    final currentCaffeine = calculateCaffeineAmount();

    return Scaffold(
      appBar: AppBar(title: Calendar(), actions: [AppTitle()]), //追加
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("記録", style: TextStyle(fontWeight: FontWeight.bold)),

              // カフェイン量表示
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                selectedDateTime,
                              ),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text("飲み物の種類", style: TextStyle(fontWeight: FontWeight.bold)),
              Meun(
                key: ValueKey(selectedDrink), // キーを追加してリビルドを強制
                onDrinkChanged: (drink) {
                  setState(() {
                    selectedDrink = drink;
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
                        offset: Offset(0, 3), // changes position of shadow
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
                      key: ValueKey(selectedAmount), // キーを追加してリビルドを強制
                      onAmountChanged: (amount) {
                        setState(() {
                          selectedAmount = amount;
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
                    Text(
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
                            offset: Offset(0, 3), // changes position of shadow
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

String selecteDrink = "コーヒー"; // このグローバル変数が問題を起こす可能性

class _MeunState extends State<Meun> {
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 160),
        child: DropdownButtonFormField(
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(left: 10),
            border: OutlineInputBorder(),
          ),
          value: selecteDrink, //初期値
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
              selecteDrink = newValue!;
            });
            widget.onDrinkChanged(newValue!);
          },
        ),
      ),
    );
  }
}

// DrinkButton、TimeButton、RecoedButtonクラスは既存のまま維持
class DrinkButton extends StatefulWidget {
  final Function(int) onAmountChanged;

  const DrinkButton({Key? key, required this.onAmountChanged})
    : super(key: key);

  @override
  _DrinkButtonState createState() => _DrinkButtonState();
}

class _DrinkButtonState extends State<DrinkButton> {
  int selectedIndex = -1; // 選択されたボタンのインデックス

  @override
  void initState() {
    super.initState();
    // 初期選択を200mlに設定
    selectedIndex = 0;
  }

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
        // 1杯 200ml
        drinkCupButton(
          0,
          "1杯",
          "assets/drink_coffee_cup07_american.png",
          "200ml",
          200,
        ),
        // 1缶 350ml
        drinkCupButton(1, "1缶", "assets/can_coffee.png", "350ml", 350),
        // ペットボトル1本 500ml
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color:
                    selectedIndex == 2
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
                        "assets/petbottle_water_full.png", // パスを修正
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
                    widget.onAmountChanged(500); // 500mlに修正
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
        // 就寝時間ボタン
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
                              final TimeOfDay? picked = await showTimePicker(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
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
                      style: TextStyle(
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

        // 起床時間ボタン（修正版）
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
                              final TimeOfDay? picked = await showTimePicker(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
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
                      style: TextStyle(
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
      title: TextField(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10,
              ),
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
              // 時間を保存する処理
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
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
        side: BorderSide(color: Colors.orange, width: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Text("記録", style: TextStyle(fontSize: 20, color: Colors.orange)),
      ),
    );
  }
}
