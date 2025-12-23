import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bgm_provider.dart';
import '6_nitice_button.dart';
import 'credit_page.dart';

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
            title: '通知設定',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettings(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const BgmVolumeControl(),
          const SizedBox(height: 16),
          _item(
            context,
            title: 'クレジット',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreditPage(),
                ),
              );
            },
          ),
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

class BgmVolumeControl extends ConsumerWidget {
  const BgmVolumeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(bgmVolumeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BGM音量',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: '${(volume * 100).toInt()}%',
                  onChanged: (value) {
                    ref.read(bgmVolumeProvider.notifier).state = value;
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: TextEditingController(
                    text: '${(volume * 100).toInt()}',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null && intValue >= 0 && intValue <= 100) {
                      ref.read(bgmVolumeProvider.notifier).state =
                          intValue / 100.0;
                    }
                  },
                  decoration: InputDecoration(
                    suffix: const Text('%'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: () async {
        // フォーカス解除（TextFieldがあるため）
        FocusScope.of(context).unfocus();
        // BGM停止は先に実行
        final player = ref.read(bgmPlayerProvider);

        try {
          // ログアウト実行前にBGM停止
          await player.stop();
        } catch (_) {
          // 失敗してもログアウトは続行
        }
        // サインアウト
        try {
          await Supabase.instance.client.auth.signOut();
          if (!context.mounted) return;
          // サインアウト後に明示的に遷移（ルーター再評価待ちを避ける）
          context.go('/login'); // ルートは実プロジェクトのログインパスに合わせて
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(content: Text('ログアウトに失敗しました: $error')),
          );
        }
      },
      child: const Text(
        'ログアウト',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
