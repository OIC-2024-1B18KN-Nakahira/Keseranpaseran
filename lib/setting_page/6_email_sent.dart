import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailSentPage extends StatelessWidget {
  const EmailSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メール送信完了')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '送られてきたメールのURLからパスワードを再設定してください',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/account'), // ルートへ戻る
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
