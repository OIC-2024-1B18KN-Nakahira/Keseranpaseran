import 'package:flutter/material.dart';

class Record extends StatelessWidget {
  const Record({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Calendar(), actions: [AppTitle()]));
  }
}

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(Icons.calendar_today, size: 40, color: Colors.grey),
        Padding(
          padding: const EdgeInsets.only(top: 15, left: 7),
          child: Text("6/2", style: TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(children: [Text("カフェイン摂取量"), Text("○○mg/日")]),
        Text("睡眠時間"),
        Text("○○時間/日"),
      ],
    );
  }
}
