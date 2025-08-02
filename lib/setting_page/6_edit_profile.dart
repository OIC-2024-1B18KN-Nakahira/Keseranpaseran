import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keseranpaseran/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _appNameController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isPregnant = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _appNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ユーザーデータを読み込み
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showError('ユーザーがログインしていません');
        return;
      }

      // Supabaseからユーザー情報を取得
      final response =
          await supabase
              .from('users')
              .select('age, is_pregnant')
              .eq('id', user.id)
              .single();

      // Providerの値も取得
      final currentAge = ref.read(ageProvider);
      final currentIsPregnant = ref.read(pregnantProvider);

      setState(() {
        // Supabaseのデータを優先し、なければProviderの値を使用
        _ageController.text = (response['age'] ?? currentAge).toString();
        _isPregnant = response['is_pregnant'] ?? currentIsPregnant;

        // デフォルト値を設定
        _nicknameController.text = user.userMetadata?['nickname'] ?? '';
        _bioController.text = user.userMetadata?['bio'] ?? '';
        _appNameController.text = 'ケセランパセラン'; // デフォルトのアプリ名
      });
    } catch (error) {
      print('ユーザーデータ取得エラー: $error');
      _showError('データの読み込みに失敗しました');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // プロフィールを保存
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showError('ユーザーがログインしていません');
        return;
      }

      final age = int.tryParse(_ageController.text) ?? 0;

      // Supabaseのusersテーブルを更新
      await supabase.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'age': age,
        'is_pregnant': _isPregnant,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // ユーザーメタデータを更新（ニックネームと自己紹介）
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'nickname': _nicknameController.text,
            'bio': _bioController.text,
            'app_name': _appNameController.text,
          },
        ),
      );

      // Providerの値も更新
      ref.read(ageProvider.notifier).state = age;
      ref.read(pregnantProvider.notifier).state = _isPregnant;

      _showSuccess('プロフィールを更新しました');

      // 少し待ってから前の画面に戻る
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.pop();
      }
    } catch (error) {
      print('プロフィール保存エラー: $error');
      _showError('保存に失敗しました: ${error.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        backgroundColor: Colors.orange.shade100,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ニックネーム
                              TextFormField(
                                controller: _nicknameController,
                                decoration: const InputDecoration(
                                  labelText: 'ユーザー名',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'ユーザー名を入力してください';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // 年齢
                              TextFormField(
                                controller: _ageController,
                                decoration: const InputDecoration(
                                  labelText: '年齢',
                                  border: OutlineInputBorder(),
                                  suffixText: '歳',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '年齢を入力してください';
                                  }
                                  final age = int.tryParse(value);
                                  if (age == null || age < 0 || age > 150) {
                                    return '有効な年齢を入力してください（0-150）';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // 妊娠の有無
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '妊娠の有無',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SwitchListTile(
                                        title: Text(
                                          _isPregnant ? '妊娠中' : '妊娠していない',
                                        ),
                                        value: _isPregnant,
                                        onChanged: (value) {
                                          setState(() {
                                            _isPregnant = value;
                                          });
                                        },
                                        activeColor: Colors.pink,
                                      ),
                                      if (_isPregnant)
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            left: 16,
                                            top: 8,
                                          ),
                                          child: Text(
                                            '※ 妊娠中の方は、カフェイン摂取量の基準が異なります',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // アプリ名のカスタマイズ
                              TextFormField(
                                controller: _appNameController,
                                decoration: const InputDecoration(
                                  labelText: 'ケセランパセラン名',
                                  border: OutlineInputBorder(),
                                  helperText: 'ケセランパセランに好きな名前を付けれます。',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'ケセランパセランンの名前を入力してください';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // 自己紹介
                              TextFormField(
                                controller: _bioController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: '自己紹介',
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 保存ボタン
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              _isSaving
                                  ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('保存中...'),
                                    ],
                                  )
                                  : const Text(
                                    '保存',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
