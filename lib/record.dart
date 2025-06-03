import 'package:flutter/material.dart';
import 'widget/appbar_widget.dart';

class Record extends StatelessWidget {
  const Record({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Calendar(), actions: [AppTitle()]),
      body: Column(
        children: [
          Text("記録"),
          Text("カフェインをとった時間"),
          Text("2025年1月1日 　12:00"),
          Text("飲み物の種類"),
        ],
      ),
    );
  }
}

