import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});
  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _form = GlobalKey<FormState>();

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
              TextFormField(readOnly: true, initialValue: 'old@example.com', decoration: const InputDecoration(labelText: '現在')),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: '新しいメール')),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: '新しいメール（確認）')),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_form.currentState!.validate()) {
                      context.pushReplacementNamed('emailSent');
                    }
                  },
                  child: const Text('変更する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
