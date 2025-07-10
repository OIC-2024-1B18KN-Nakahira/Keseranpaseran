import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

final supabase = Supabase.instance.client;

class AccountCreate extends StatelessWidget {
  const AccountCreate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Form()));
  }
}

class Form extends StatefulWidget {
  const Form({super.key});

  @override
  State<Form> createState() => _FormState();
}

class _FormState extends State<Form> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void clearFields() {
    emailController.clear();
    passwordController.clear();
  }

  Future<void> signUpNewUser() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('サインアップ開始'); // デバッグ用ログ
      final AuthResponse = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print('AuthResponse: ${AuthResponse.user}'); // デバッグ用ログ

      if (AuthResponse.user != null) {
        print('ユーザー作成成功'); // デバッグ用ログ
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('アカウントが作成されました。')));
        clearFields();

        // context.push の代わりに context.go を試す
        if (mounted) {
          // Widgetがまだマウントされているか確認
          context.go('/login');
        }
      } else {
        print('ユーザー作成失敗: AuthResponse.user is null'); // デバッグ用ログ
        setState(() {
          errorMessage = 'アカウント作成に失敗しました';
        });
      }
    } on AuthException catch (e) {
      print('AuthException: ${e.message}'); // デバッグ用ログ
      setState(() {
        errorMessage = e.message;
      });
    } catch (error) {
      print('予期しないエラー: $error'); // デバッグ用ログ
      setState(() {
        errorMessage = 'An unexpected error occurred: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Text(
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
