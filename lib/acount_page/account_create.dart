import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keseranpaseran/provider.dart';

final supabase = Supabase.instance.client;

class AccountCreate extends StatelessWidget {
  const AccountCreate({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Form()));
  }
}

class Form extends ConsumerStatefulWidget {
  const Form({super.key});

  @override
  ConsumerState<Form> createState() => _FormState();
}

class _FormState extends ConsumerState<Form> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  String successMessage = '';

  // アカウント作成処理
  Future<void> signUpNewUser() async {
    // 入力チェック
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'メールアドレスとパスワードを入力してください';
      });
      return;
    }

    // providerから年齢と妊娠状態を取得してチェック
    final age = ref.read(ageProvider);
    final isPregnant = ref.read(pregnantProvider);

    print('=== アカウント作成開始 ===');
    print('Email: ${emailController.text.trim()}');
    print('Provider Age: $age');
    print('Provider Pregnant: $isPregnant');

    // 年齢が設定されていない場合は警告
    if (age == 0) {
      setState(() {
        errorMessage = '年齢設定画面で年齢を入力してください';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('=== Step 1: Supabase認証開始 ===');

      // Supabaseでアカウント作成（メール確認必須）
      final AuthResponse response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
        data: {
          'age': age,
          'is_pregnant': isPregnant,
        },
      );

      print('AuthResponse User: ${response.user?.id}');
      print(
        'AuthResponse Session: ${response.session?.accessToken != null ? "あり" : "なし"}',
      );

      if (response.user != null) {
        print('=== Step 2: メール送信完了 ===');

        if (mounted) {
          setState(() {
            errorMessage = '';
            successMessage =
                '確認メールを送信しました。\nメール内のリンクをクリックしてアカウントを有効化してください。';
          });

          // 5秒後にログイン画面に戻る
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });

          // providerをリセット
          ref.read(ageProvider.notifier).state = 0;
          ref.read(pregnantProvider.notifier).state = false;
        }
      } else {
        print('AuthResponse.user is null');
        setState(() {
          errorMessage = 'アカウント作成に失敗しました（ユーザー情報がnull）';
        });
      }
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      setState(() {
        errorMessage = 'アカウント作成エラー: ${e.message}';
      });
    } catch (error) {
      print('予期しないエラー: $error');
      setState(() {
        errorMessage = 'エラーが発生しました: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // デバッグ用：現在のproviderの値を取得
    ref.watch(ageProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: Column(
            children: [
              Text(
                'アカウントを作成',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Divider(
                height: 20,
                thickness: 2,
                indent: 50,
                endIndent: 50,
                color: Color.fromARGB(255, 212, 211, 211),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextBox(
            controller: emailController,
            passwordController: passwordController,
          ),
        ),
        // エラーメッセージを表示
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        // 成功メッセージを表示
        if (successMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              successMessage,
              style: const TextStyle(color: Colors.green, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: AccountCreatButton(
            onPressed: isLoading ? null : signUpNewUser,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

// TextBoxクラス
class TextBox extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController passwordController;

  const TextBox({
    super.key,
    required this.controller,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'メールアドレス',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: passwordController,
            decoration: InputDecoration(
              hintText: '8文字以上のパスワードを入力してください',
              labelText: 'パスワード',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            obscureText: true,
          ),
        ),
      ],
    );
  }
}

class AccountCreatButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const AccountCreatButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'アカウント作成',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
