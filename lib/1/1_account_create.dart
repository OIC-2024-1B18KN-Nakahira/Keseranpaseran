import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keseranpaseran/1/2_account_create2.dart';

class AccountCreate2 extends StatelessWidget {
  const AccountCreate2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              "アカウント作成",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextBox(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: BackLoginButton(),
          ),
        ],
      ),
    );
  }
}

class TextBox extends StatelessWidget {
  const TextBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text("年齢")),
        TextField(
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.all(8.0), child: Text("妊娠中")),
        YesNOButton(),
      ],
    );
  }
}

class YesNOButton extends StatelessWidget {
  const YesNOButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {},
              child: Text(
                "はい",
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {},
              child: Text(
                "いいえ",
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => context.push('/account_create'),
            child: Text(
              "次へ",
              style: TextStyle(color: Colors.white, fontSize: 30),
            ),
          ),
        ),
      ],
    );
  }
}

class BackLoginButton extends StatelessWidget {
  const BackLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        "ログイン画面はこちら",
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
