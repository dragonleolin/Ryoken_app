import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../storage/token_storage.dart';

class ApiService {
  final AppEnv env;
  ApiService(this.env);

  Future<http.Response> _send(String method, String path,
      {Map<String, String>? headers, Object? body, Map<String, dynamic>? query}) async {
    final token = await TokenStorage.readToken();
    final uri = Uri.parse('${env.baseUrl}$path').replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));
    final baseHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    switch (method) {
      case 'GET':
        return await http.get(uri, headers: baseHeaders);
      case 'POST':
        return await http.post(uri, headers: baseHeaders, body: body is String ? body : jsonEncode(body ?? {}));
      case 'PUT':
        return await http.put(uri, headers: baseHeaders, body: body is String ? body : jsonEncode(body ?? {}));
      case 'DELETE':
        return await http.delete(uri, headers: baseHeaders);
      default:
        throw UnsupportedError('Method $method');
    }
  }

  // ==== Auth & User ====
  Future<http.Response> register(Map<String, dynamic> dto) => _send('POST', '/api/auth/register', body: dto);
  Future<http.Response> login(String email, String password) async {
    final response = await _send('POST', '/api/auth/login', body: {'account': email, 'password': password});
    if (response.statusCode == 200) {
      print("✅ 登入成功: ${response.body}");
    } else {
      print("❌ 登入失敗: ${response.statusCode} - ${response.body}");
    }
  }
  Future<http.Response> profile() => _send('GET', '/api/user/profile');
  Future<http.Response> updateProfile(Map<String, dynamic> dto) =>
      _send('PUT', '/api/user/profile', body: dto);

  // ==== Notification ====
  Future<http.Response> updateNotificationSetting(Map<String, dynamic> dto) =>
      _send('POST', '/api/user/updateNotificationSetting', body: dto);
  Future<http.Response> getNotificationSetting(String email) =>
      _send('GET', '/api/notification/setting/$email');

  // ==== Subscription ====
  Future<http.Response> getPlans() => _send('GET', '/api/subscription/plans');
  Future<http.Response> getSubStatus() => _send('GET', '/api/subscription/status');
  Future<http.Response> applyPlan(String planId) =>
      _send('POST', '/api/subscription/apply', query: {'planId': planId});
  Future<http.Response> cancelPlan() => _send('POST', '/api/subscription/cancel');

  // ==== Admin ====
  Future<http.Response> adminUsers() => _send('GET', '/api/admin/users');
  Future<http.Response> adminUserDetail(String email) => _send('GET', '/api/admin/user/$email');
  Future<http.Response> adminCreatePlan(Map<String, dynamic> dto) =>
      _send('POST', '/api/admin/plan/create', body: dto);
  Future<http.Response> adminBroadcastPlan(Map<String, dynamic> dto) =>
      _send('POST', '/api/admin/plan/broadcast', body: dto);
}
