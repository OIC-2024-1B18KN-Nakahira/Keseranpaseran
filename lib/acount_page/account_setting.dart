import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keseranpaseran/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class TextBox extends ConsumerStatefulWidget {
  const TextBox({super.key});

  @override
  ConsumerState<TextBox> createState() => _TextBoxState();
}

class _TextBoxState extends ConsumerState<TextBox> {
  final TextEditingController ageController = TextEditingController();
  bool isPregnant = false;
  String errorMessage = '';

  @override
  void dispose() {
    ageController.dispose();
    super.dispose();
  }

  // 年齢が正しく入力されているかチェック
  bool isAgeValid() {
    final ageText = ageController.text.trim();
    if (ageText.isEmpty) return false;
    final age = int.tryParse(ageText);
    return age != null && age > 0 && age <= 120;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text("年齢")),
        TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "年齢を入力してください",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {
              errorMessage = '';
            });
          },
        ),
        // エラーメッセージ表示エリア
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Padding(padding: const EdgeInsets.all(8.0), child: Text("妊娠中")),
        YesNoButton(
          isPregnant: isPregnant,
          onPregnantChanged: (value) {
            setState(() {
              isPregnant = value;
            });
          },
          isAgeValid: isAgeValid(),
          ageController: ageController,
          onErrorChanged: (error) {
            setState(() {
              errorMessage = error;
            });
          },
        ),
      ],
    );
  }
}

class YesNoButton extends ConsumerWidget {
  final bool isPregnant;
  final Function(bool) onPregnantChanged;
  final bool isAgeValid;
  final TextEditingController ageController;
  final Function(String) onErrorChanged;

  const YesNoButton({
    super.key,
    required this.isPregnant,
    required this.onPregnantChanged,
    required this.isAgeValid,
    required this.ageController,
    required this.onErrorChanged,
  });

  // 保存時のバリデーション処理
  void saveData(BuildContext context, WidgetRef ref) {
    final ageText = ageController.text.trim();

    // 年齢が空の場合
    if (ageText.isEmpty) {
      onErrorChanged('年齢を入力してください');
      return;
    }

    // 年齢が数字でない場合
    final age = int.tryParse(ageText);
    if (age == null) {
      onErrorChanged('年齢は数字で入力してください');
      return;
    }

    // 年齢が範囲外の場合
    if (age <= 0 || age > 120) {
      onErrorChanged('年齢は1歳から120歳の間で入力してください');
      return;
    }

    // バリデーション成功時、providerに保存
    onErrorChanged('');
    ref.read(ageProvider.notifier).state = age;
    ref.read(pregnantProvider.notifier).state = isPregnant;

    print('=== account_setting 保存完了 ===');
    print('保存された年齢: $age');
    print('保存された妊娠状態: $isPregnant');

    // アカウント作成画面に遷移
    context.push('/account_create');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPregnant ? Colors.green : Colors.grey,
              ),
              onPressed: () => onPregnantChanged(true),
              child: Text(
                "はい",
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: !isPregnant ? Colors.green : Colors.grey,
              ),
              onPressed: () => onPregnantChanged(false),
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
            onPressed: () => saveData(context, ref),
            child: Text(
              "保存",
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
      onPressed: () => context.push('/account_create'),
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
