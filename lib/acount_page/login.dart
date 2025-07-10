import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Text(
                    'アカウントにログイン',
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
                controller: TextEditingController(),
                passwordController: TextEditingController(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: LoginButton(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [PassButton(), RegisterButton()]),
            ),
          ],
        ),
      ),
    );
  }
}

class TextBox extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController passwordController;
  const TextBox({super.key, required this.controller, required this.passwordController});

  @override
  State<TextBox> createState() => _TextBoxState();
}

class _TextBoxState extends State<TextBox> {
  bool isObscure = true;

  String text = '';
  void _onChanged(String e) {
    setState(() {
      text = e;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('メールアドレス'),
        TextField(
          controller: widget.controller,
          decoration: const InputDecoration(
            hintText: 'メールアドレス',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
          ),
        ),
        Text('パスワード'),
        TextField(
          controller: widget.passwordController,
          onChanged: _onChanged,
          obscureText: isObscure, // パスワードが初めから見えないように設定
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  isObscure = !isObscure;
                });
              },
            ),
            hintText: 'パスワード',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      onPressed: () => context.push('/home'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: Text(
          'ログイン',
          style: TextStyle(color: Colors.white, fontSize: 30),
        ),
      ),
    );
  }
}

class PassButton extends StatelessWidget {
  const PassButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        'パスワードを忘れた方はこちら',
        style: TextStyle(
          color: Colors.blue,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
        ),
      ),
    );
  }
}

class RegisterButton extends StatelessWidget {
  const RegisterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.push('/account_create2'),
      child: Text(
        'アカウント作成はこちら',
        style: TextStyle(
          color: Colors.blue,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
        ),
      ),
    );
  }
}
