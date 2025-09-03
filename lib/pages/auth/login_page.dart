import 'package:flutter/material.dart';
import 'package:ryoken_app/pages/auth/register_page.dart';

import '../../core/config/env.dart';
import '../../core/network/api_service.dart';
import '../home/home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool _obscurePassword = true; // 密碼是否隱藏
  bool isLoading = false; // 登入中狀態
  String? error; // 錯誤訊息

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
        // ✅ 登入成功 → 導向主頁
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        // ❌ 登入失敗 → 顯示提示框
        await showLoginErrorDialog(context);
      }
    } catch (e) {
      await showLoginErrorDialog(context,
          message: "登入時發生錯誤，請稍後再試");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  /// Google 登入
  Future<void> _handleGoogleLogin() async {
    try {
      print("✅ Google _handleGoogleLogin");
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: "504321035408-1aiu4fah23s5r53nh24a8gafv6ceo51s.apps.googleusercontent.com",
      );

      final googleUser = await googleSignIn.signIn();
      print("✅ Google googleUser=$googleUser");
      if (googleUser == null) {
        // 使用者取消登入
        showGoogleFailedDialog(context);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final email = googleUser.email;
      final name = googleUser.displayName ?? "";
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        print("❌ Google 沒有回傳 idToken");
        showGoogleFailedDialog(context);
        return;
      }

      print("✅ Google 登入成功: email=$email, name=$name, idToken=$idToken");

      // 把資料送到後端
      final response = await ApiService.googleLogin(
        email: email,
        name: name,
        token: idToken,
      );
      if (response.statusCode == 200) {
        // 登入成功 → 進入首頁
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        print("❌ 後端登入失敗: ${response.body}");
        showGoogleFailedDialog(context);
      }
    } catch (e, stack) {
      print("❌ Google 登入錯誤: $e");
      print(stack);
      showGoogleFailedDialog(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 上方 Logo
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // 表單
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 🔹 Email
                    TextFormField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        hintText: "電子郵件",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                      v != null && v.contains('@') ? null : "請輸入正確 Email",
                    ),
                    const SizedBox(height: 16),

                    // 🔹 密碼 (含顯示/隱藏)
                    TextFormField(
                      controller: passCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "密碼",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
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

                    const SizedBox(height: 16),

                    // 🔹 登入按鈕 (帶 Loading)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _login();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                            : const Text("登入"),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 🔹 註冊按鈕
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );

                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("🎉 註冊成功，請登入")),
                          );
                        }
                      },
                      child: const Text(
                        "註冊",
                        style: TextStyle(color: AppColors.gold),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔹 Google 登入按鈕
                    ElevatedButton.icon(
                      onPressed: _handleGoogleLogin,
                      icon: const Icon(Icons.login, color: AppColors.gold),
                      label: const Text("使用 Google 登入"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: AppColors.gold,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 🔹 LINE 登入
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble, color: AppColors.gold),
                      label: const Text("使用 LINE 登入"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: AppColors.gold,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                    // 🔹 Footer
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Text(
                        "不構成投資建議的責任",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 自訂登入錯誤提示框
Future<void> showLoginErrorDialog(BuildContext context,
    {String message = "帳號或密碼錯誤，請重新輸入"}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.gold, size: 48),
              const SizedBox(height: 12),
              const Text(
                "登入失敗",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("重試"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: 忘記密碼流程
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.gold),
                        foregroundColor: const Color(0xFFFFD700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("忘記密碼?"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showGoogleFailedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.gold, size: 48),
            const SizedBox(height: 12),
            const Text(
              "第三方登入失敗",
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Google / Apple 登入驗證未通過，請重試\n或改用帳密登入",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
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
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // 👇 跳去帳號密碼登入頁
                      // Navigator.pushNamed(context, "/login");
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gold, width: 1),
                      foregroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("使用帳密登入"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}



