import 'package:flutter/material.dart';

class AppColors {
  static const Color gold = Color(0xFFBE942A);
  static const Color black = Color(0xFF0C0C0C);
}

class AppEnv {
  final String env;
  final String baseUrl;
  const AppEnv({required this.env, required this.baseUrl});

  factory AppEnv.fromDefine() {
    const env = String.fromEnvironment('ENV', defaultValue: 'local');
    const base = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
    return AppEnv(env: env, baseUrl: base);
  }

  String get oauthGoogle => '$baseUrl/oauth2/authorization/google';
  String get oauthLine => '$baseUrl/oauth2/authorization/line';
}
