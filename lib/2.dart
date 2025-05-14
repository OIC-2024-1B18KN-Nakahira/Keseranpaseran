import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '1.dart';

class AccountCreate extends StatelessWidget {
  const AccountCreate({super.key});

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
              child: TextBox(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: AccountCreatButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountCreatButton extends StatelessWidget {
  const AccountCreatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
      onPressed: () => context.push('/account'),
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
