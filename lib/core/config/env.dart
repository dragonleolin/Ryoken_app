import 'dart:io';

import 'package:flutter/material.dart';

class AppColors {
  // static const Color gold = Color(0xFFBE942A);
  // static const Color black = Color(0xFF0C0C0C);
  // static const Color goldSoft = Color(0xFFB7932A);
  // static const Color bg = Color(0xFF0B0F13);
  // static const Color card = Color(0xFF11161D);
  // static const Color muted = Color(0xFF8B93A1);

  static const goldSoft = Color(0xFFB7932A);
  static const ok = Color(0xFF22C55E); // 綠
  static const warn = Color(0xFFF59E0B); // 黃
  static const danger = Color(0xFFEF4444); // 紅

  static const Color bg = Color(0xFF0B0F13);      // 深背景
  static const Color card = Color(0xFF11161D);    // 卡片底
  static const Color gold = Color(0xFFD4AF37);    // 金色
  static const Color muted = Color(0xFF8B93A1);   // 淺灰文字

  // 白色色階
  static const Color white = Colors.white;             // 純白
  static const Color white70 = Colors.white70;         // 70% 白
  static const Color white54 = Colors.white54;         // 54% 白
  static const Color white38 = Colors.white38;         // 38% 白
  static const Color white24 = Colors.white24;         // 24% 白
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
  String get oauthGoogle => '$baseUrl/oauth2/authorization/google';
  String get oauthLine => '$baseUrl/oauth2/authorization/line';
}

