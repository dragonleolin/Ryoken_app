import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool isLoading = false;
  String? error;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await ApiService.login(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      if (response.statusCode == 200) {
        print("✅ 登入成功: ${response.body}");
        // TODO: 登入成功後導向主頁
        // Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          error = "登入失敗: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        error = "登入時發生錯誤: $e";
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),

              // 🔹 Logo 區塊（你原本的圖片放 assets）
              Center(
                child: Image.asset(
                  "assets/images/logo.png", // 支援 png/jpeg/svg
                  height: 120,
                ),
              ),
              const SizedBox(height: 40),

              // 🔹 Email 輸入框
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                v != null && v.contains('@') ? null : "請輸入正確 Email",
              ),
              const SizedBox(height: 10),

              // 🔹 密碼輸入框
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: "密碼"),
                obscureText: true,
                validator: (v) =>
                v != null && v.length >= 6 ? null : "至少 6 碼",
              ),
              const SizedBox(height: 16),

              // 🔹 錯誤訊息
              if (error != null)
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 12),

              // 🔹 登入按鈕
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: isLoading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("登入"),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔹 註冊 / Google / LINE 登入（保留樣式）
              // TODO: 這裡放你原本的設計，我沒有動 UI，只示範接上 login
            ],
          ),
        ),
      ),
    );
  }
}
