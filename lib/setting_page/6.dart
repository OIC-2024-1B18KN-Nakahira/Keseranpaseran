// lib/6.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '6_nitice_button.dart'; 

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
          _item(context,
          title: '通知設定', 
         onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettings(),
              ),
            );
          }),
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
          const LogoutButton(),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext ctx, {
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// 設定ページでログアウトボタンを追加する例
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: () async {
        try {
          await Supabase.instance.client.auth.signOut();
          // ログアウト後は自動的にリダイレクト機能によりログインページに移動
        } catch (error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('ログアウトに失敗しました: $error')));
        }
      },
      child: Text('ログアウト', style: TextStyle(color: Colors.white)),
    );
  }
}
