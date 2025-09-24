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
      print("✅ headerToken=$token");
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// 取會員與幣種資料
  static Future<Map<String, dynamic>> fetchMembership(String timeframe) async {
    final url = Uri.parse("$baseUrl/api/homepage/membership?timeframe=$timeframe");
    print("✅ fetchMembership url: $url");

    final headers = await ApiService._getHeaders(withAuth: true);
    print("🔍 Headers used in request: $headers");

    final res = await http.get(
      url,
      headers: headers,  // ✅ 改這裡，使用帶有 Bearer token 的 headers
    );

    print("✅ fetchMembership res: ${res.statusCode}");
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("fetchMembership 失敗: ${res.body}");
    }
  }

  /// 取首頁數據
  static Future<Map<String, dynamic>> fetchHomePageData({
    required String cryptocurrency,
    required String timeframe, required String investmentType,
  }) async {
    final headers = await ApiService._getHeaders(withAuth: true);
    final url = Uri.parse(
        "$baseUrl/api/homepage?cryptocurrency=$cryptocurrency&timeframe=$timeframe&investmentType=$investmentType");
    print("✅ fetchHomePageData url: $url");
    final res = await http.get(
      url,
      headers: headers,
    );
    print("✅ fetchHomePageData res: $res");
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("fetchHomePageData 失敗: ${res.body}");
    }
  }

  // 取 Subscription Plans
  static Future<Map<String, dynamic>> fetchPlans() async {
    final headers = await ApiService._getHeaders(withAuth: true);
    final url = Uri.parse(
        "$baseUrl/api/admin/subscription");
    print("✅ fetchPlans url: $url");
    final res = await http.get(
      url,
      headers: headers,
    );
    print("✅ fetchPlans res.statusCode: ${res.statusCode}");
    print("✅ fetchPlans res.body: ${res.body}");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return {
        "currentPlan": data["currentPlan"],
        "plans": List<Map<String, dynamic>>.from(data["plans"]),
      };
    } else {
      throw Exception("fetchPlans 失敗: ${res.body}");
    }
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
      print("✅ token=$token");
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
      print("✅ token=$token");
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
