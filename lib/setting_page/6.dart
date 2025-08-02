// lib/6.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Account extends StatelessWidget {
  const Account({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          _item(
            context,
            title: 'プロフィール編集',
            onTap: () => context.pushNamed('editProfile'),
          ),
          _item(
            context,
            title: 'メールアドレス変更',
            onTap: () => context.pushNamed('changeEmail'),
          ),
          const Divider(height: 32),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {}, //ログアウト実装前
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('ログアウト'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext ctx,
      {required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
