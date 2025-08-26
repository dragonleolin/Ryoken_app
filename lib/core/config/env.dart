import 'dart:io';

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
    return AppEnv(env: env, baseUrl: AppEnv.platformBaseUrl);
  }

  /// 依平台自動決定 baseUrl
  static String get platformBaseUrl =>
      Platform.isAndroid ? "http://10.0.2.2:8080" : "http://localhost:8080";

  /// OAuth endpoints
  String get oauthGoogle => 'http://localhost:8080/oauth2/authorization/google';
  String get oauthLine => '$baseUrl/oauth2/authorization/line';
}

