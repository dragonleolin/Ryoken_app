import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

class ApiService {
  static String get baseUrl => AppEnv.platformBaseUrl;


  // 🔹 共用 http headers
  static Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // 🔹 登入
  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        "account": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['data']['token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }
    }

    return response;
  }

  /// 註冊
  static Future<http.Response> register({
    required String account,
    required String password,
    required String email,
    required String nickName,
    String? phone,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/register");
    final body = jsonEncode({
      "account": account,
      "password": password,
      "email": email,
      "nickName": nickName,
      "phone": phone,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    return response;
  }

  /// Google 登入 API
  static Future<http.Response> googleLogin({
    required String email,
    required String name,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/oauth/google");
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        "email": email,
        "name": name,
        "idToken": token, // ✅ 把 Google idToken 傳到 body
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['data']['token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }
    }
    return response;
  }

  // 🔹 取得個人資料
  static Future<http.Response> getProfile() async {
    final url = Uri.parse('$baseUrl/api/user/profile');
    final response = await http.get(
      url,
      headers: await _getHeaders(withAuth: true),
    );
    return response;
  }

  // 🔹 登出（清除 Token）
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    print("🔒 Token 已清除");
  }
}
