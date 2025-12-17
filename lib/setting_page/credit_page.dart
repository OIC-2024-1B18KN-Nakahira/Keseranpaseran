import 'package:flutter/material.dart';
import 'dart:convert';

class CreditPage extends StatefulWidget {
  const CreditPage({super.key});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  late Future<Map<String, dynamic>> creditData;

  @override
  void initState() {
    super.initState();
    creditData = _loadCredits();
  }

  Future<Map<String, dynamic>> _loadCredits() async {
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/credits.json');
    return json.decode(jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('クレジット'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: creditData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final app = data['app'];
          final libraries = List<Map<String, dynamic>>.from(data['libraries']);
          final materials = List<Map<String, dynamic>>.from(data['materials']);
          final license = data['license'];
          final contacts = List<Map<String, dynamic>>.from(data['contact']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アプリ名
                Text(
                  app['name'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  app['nameEn'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // アプリ情報
                _buildSection(
                  title: 'アプリ情報',
                  children: [
                    _buildInfoRow('開発', app['developer']),
                    _buildInfoRow('バージョン', app['version']),
                    _buildInfoRow('リリース日', app['releaseDate']),
                  ],
                ),
                const SizedBox(height: 32),

                // 使用ライブラリ
                _buildSection(
                  title: '使用ライブラリ',
                  children: libraries
                      .map((lib) => _buildLibraryItem(lib['name'], lib['author']))
                      .toList(),
                ),
                const SizedBox(height: 32),

                // 素材
                _buildSection(
                  title: '素材',
                  children: materials
                      .map((mat) => _buildMaterialItem(mat['name'], mat['description']))
                      .toList(),
                ),
                const SizedBox(height: 32),

                // ライセンス
                _buildSection(
                  title: 'ライセンス',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        license,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 連絡先
                _buildSection(
                  title: '連絡先',
                  children: contacts
                      .map((contact) =>
                      _buildContactRow(contact['label'], contact['value']))
                      .toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem(String name, String author) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'by $author',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }
}
