import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  String? _msg;

  Future<void> _doRegister() async {
    setState(() { _busy = true; _msg = null; });
    try {
      final api = context.read<ApiService>();
      final resp = await api.register({'email': _email.text.trim(), 'password': _password.text, 'name': _name.text});
      setState(() => _msg = resp.statusCode == 200 ? '註冊成功，請返回登入。' : '註冊失敗 (${resp.statusCode})');
    } catch (e) {
      setState(() => _msg = '發生錯誤：$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(decoration: const InputDecoration(hintText: '名稱'), controller: _name),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(hintText: '電子郵件'), controller: _email),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(hintText: '密碼'), controller: _password, obscureText: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _busy ? null : _doRegister, child: const Text('建立帳號')),
            ),
            if (_msg != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_msg!)),
          ],
        ),
      ),
    );
  }
}
