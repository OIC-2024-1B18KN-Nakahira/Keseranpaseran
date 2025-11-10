import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});
  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _form = GlobalKey<FormState>();
  final newEmailController = TextEditingController();
  final confirmEmailController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  String successMessage = '';
  String? currentEmail;

  @override
  void initState() {
    super.initState();
    currentEmail = supabase.auth.currentUser?.email;
  }

  @override
  void dispose() {
    newEmailController.dispose();
    confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> changeEmail() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    if (newEmailController.text.trim() != confirmEmailController.text.trim()) {
      setState(() {
        errorMessage = 'メールアドレスが一致しません';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      await supabase.auth.updateUser(
        UserAttributes(
          email: newEmailController.text.trim(),
        ),
      );

      if (mounted) {
        setState(() {
          successMessage =
              '確認メールを送信しました。\n新しいメールアドレス宛に送信された確認リンクをクリックしてください。';
        });

        // 5秒後に前の画面に戻る
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    } on AuthException catch (e) {
      setState(() {
        errorMessage = 'エラー: ${e.message}';
      });
    } catch (error) {
      setState(() {
        errorMessage = 'エラーが発生しました: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メールアドレス変更')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                readOnly: true,
                initialValue: currentEmail ?? '未設定',
                decoration: const InputDecoration(labelText: '現在のメールアドレス'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newEmailController,
                decoration: const InputDecoration(labelText: '新しいメールアドレス'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '新しいメールアドレスを入力してください';
                  }
                  if (!value.contains('@')) {
                    return '有効なメールアドレスを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmEmailController,
                decoration:
                    const InputDecoration(labelText: '新しいメールアドレス（確認）'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '確認用メールアドレスを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (successMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    successMessage,
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : changeEmail,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('変更する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
