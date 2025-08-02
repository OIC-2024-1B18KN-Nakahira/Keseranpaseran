import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keseranpaseran/provider.dart';

final supabase = Supabase.instance.client;

class AccountCreate extends StatelessWidget {
  const AccountCreate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Form()));
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

  // アカウント作成処理（修正版）
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

      // Supabaseでアカウント作成
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print('AuthResponse User: ${authResponse.user?.id}');
      print(
        'AuthResponse Session: ${authResponse.session?.accessToken != null ? "あり" : "なし"}',
      );

      if (authResponse.user != null) {
        print('=== Step 2: 認証完了待機 ===');

        // 認証が完全に処理されるまで待機
        await Future.delayed(Duration(seconds: 2));

        // 現在のセッション状態を確認
        final currentUser = supabase.auth.currentUser;
        final currentSession = supabase.auth.currentSession;

        print('Current User: ${currentUser?.id}');
        print(
          'Current Session: ${currentSession?.accessToken != null ? "あり" : "なし"}',
        );

        print('=== Step 3: データベース保存開始 ===');

        // usersテーブルにユーザー情報を保存
        await saveUserToDatabase(authResponse.user!.id, age, isPregnant);

        print('=== Step 4: 完了処理 ===');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('アカウントが作成されました'),
              backgroundColor: Colors.green,
            ),
          );

          // providerをリセット
          ref.read(ageProvider.notifier).state = 0;
          ref.read(pregnantProvider.notifier).state = false;

          context.go('/login');
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

  // usersテーブルにデータを保存する関数（シンプル版）
  Future<void> saveUserToDatabase(
    String userId,
    int age,
    bool isPregnant,
  ) async {
    print('=== データベース保存開始 ===');
    print('User ID: $userId');
    print('現在のauth.currentUser: ${supabase.auth.currentUser?.id}');
    print(
      '現在のauth.currentSession: ${supabase.auth.currentSession?.accessToken != null ? "あり" : "なし"}',
    );

    try {
      // より単純なデータ構造でテスト
      final userData = {
        'id': userId,
        'email': emailController.text.trim(),
        'age': age,
        'is_pregnant': isPregnant,
      };

      print('保存予定データ: $userData');

      // insertではなくupsertを使用（存在しない場合は挿入、存在する場合は更新）
      final response = await supabase.from('users').upsert(userData).select();

      print('=== データベース保存成功 ===');
      print('Response: $response');
    } catch (error) {
      print('=== データ保存エラー ===');
      print('Error: $error');
      print('Error Type: ${error.runtimeType}');

      // エラーをUIに表示
      if (mounted) {
        setState(() {
          errorMessage = 'データ保存エラー: $error';
        });
      }

      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // デバッグ用：現在のproviderの値を取得
    final currentAge = ref.watch(ageProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            children: [
              Text(
                'アカウントを作成',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const Divider(
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
          padding: EdgeInsets.symmetric(horizontal: 30),
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
              style: TextStyle(color: Colors.red, fontSize: 16),
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
        // デバッグ用：現在のproviderの値を表示
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: currentAge == 0 ? Colors.red[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: currentAge == 0 ? Colors.red : Colors.grey,
                width: 2,
              ),
            ),
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
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
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
