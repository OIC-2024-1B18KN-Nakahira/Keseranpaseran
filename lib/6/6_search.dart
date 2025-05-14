import 'package:flutter/material.dart';

class AccountSearchPage extends StatefulWidget {
  const AccountSearchPage({super.key});
  @override
  State<AccountSearchPage> createState() => _AccountSearchPageState();
}

class _AccountSearchPageState extends State<AccountSearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final list = [
      'ブラックホール',
      'アンドロメダ',
      'ペガサス',
      'オリオン',
    ].where((e) => e.contains(_query)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー検索')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'キーワード入力',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(list[i]),
                  trailing: const Chip(label: Text('NEW')),
                  onTap: () {}, //詳細へ実装前
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
