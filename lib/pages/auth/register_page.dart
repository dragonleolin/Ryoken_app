import 'package:flutter/material.dart';
import 'package:ryoken_app/pages/auth/login_page.dart';

import '../../core/config/env.dart';
import '../../core/network/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final accountCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nickNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  bool isLoading = false;
  String? error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await ApiService.register(
        account: emailCtrl.text,
        password: passCtrl.text,
        email: emailCtrl.text,
        nickName: nickNameCtrl.text,
        phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : "",
      );

      if (response.statusCode == 200) {
        // 註冊成功時
        showRegisterResultDialog(context, isSuccess: true);
      } else {
        // 註冊失敗時
        showRegisterResultDialog(context, isSuccess: false);
      }
    } catch (e) {
      setState(() {
        error = "發生錯誤: $e";
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
      appBar: AppBar(title: const Text("註冊")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nickNameCtrl,
                decoration: const InputDecoration(labelText: "暱稱"),
                validator: (v) => v == null || v.isEmpty ? "請輸入暱稱" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v != null && v.contains('@') ? null : "請輸入正確 Email",
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: "密碼"),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : "至少 6 碼",
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "手機號碼 (選填)"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : _register,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: isLoading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("註冊"),
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

void showRegisterResultDialog(BuildContext context, {required bool isSuccess}) {
  final icon = isSuccess ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
  final title = isSuccess ? "註冊成功" : "註冊失敗";
  final message = isSuccess
      ? "請重新進行登入，輸入您剛註冊的帳號與密碼。"
      : "帳號或信箱可能已被使用，\n請重新確認後再試一次。";

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: "Dialog",
    transitionDuration: const Duration(milliseconds: 250), // 動畫時間
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: animation,
          child: Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.gold, width: 1.2),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 300,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppColors.gold, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (!isSuccess) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("重試"),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // 👇 跳回登入頁
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.gold, width: 1),
                              foregroundColor: AppColors.gold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(isSuccess ? "返回登入頁" : "使用帳密登入"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

