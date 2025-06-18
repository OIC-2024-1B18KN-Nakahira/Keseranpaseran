import 'package:flutter/material.dart';
//他のファイルで作成したwidgetを使う
import 'widget/appbar_widget.dart'; //追加

class Record extends StatelessWidget {
  const Record({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Calendar(), actions: [AppTitle()]), //追加
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("記録", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        child: Text(
                          "2025年1月1日 　12:00",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text("飲み物の種類", style: TextStyle(fontWeight: FontWeight.bold)),
              Meun(),
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
                    child: DrinkButton(),
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
                        child: TimeButton(),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(child: RecoedButton()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Meun extends StatefulWidget {
  const Meun({super.key});

  @override
  State<Meun> createState() => _MeunState();
}

String selecteDrink = "コーヒー"; //選択された飲み物の初期値

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
                "コーヒー",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "紅茶",
              child: Text(
                "紅茶",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "緑茶",
              child: Text(
                "緑茶",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "ウーロン茶",
              child: Text(
                "ウーロン茶",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "ココア",
              child: Text(
                "ココア",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            DropdownMenuItem(
              value: "エナジードリンク",
              child: Text(
                "エナジードリンク",
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
          },
        ),
      ),
    );
  }
}

class DrinkButton extends StatefulWidget {
  const DrinkButton({Key? key}) : super(key: key);

  @override
  _DrinkButtonState createState() => _DrinkButtonState();
}

class _DrinkButtonState extends State<DrinkButton> {
  int selectedIndex = -1; // 選択されたボタンのインデックス

  Widget drinkCupButton(
    int index,
    String label,
    String imagePath,
    String volume,
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
          "0.5杯",
          "assets/drink_coffee_cup01_espresso.png",
          "350ml",
        ),
        drinkCupButton(
          1,
          "1杯",
          "assets/drink_coffee_cup07_american.png",
          "500ml",
        ),
        // 画像を2つ表示するボタン
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
                  Text("2杯"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/drink_coffee_cup07_american.png",
                        width: 40,
                        height: 50,
                      ),
                      SizedBox(width: 5),
                      Image.asset(
                        "assets/drink_coffee_cup07_american.png",
                        width: 40,
                        height: 50,
                      ),
                    ],
                  ),
                  Text("1L"),
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
  const TimeButton({super.key});

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
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => const TimeDialog(),
                              );
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
                      "00:00",
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
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => const TimeDialog(),
                              );
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
                      "00:00",
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
  const RecoedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.orange, width: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Text("記録", style: TextStyle(fontSize: 20, color: Colors.orange)),
      ),
    );
  }
}
