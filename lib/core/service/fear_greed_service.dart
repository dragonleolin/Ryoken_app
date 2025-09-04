import 'dart:convert';
import 'package:http/http.dart' as http;

class FearGreed {
  final int value;                 // 0–100
  final String classification;     // Extreme Fear / Fear / Neutral / Greed / Extreme Greed
  final DateTime timestamp;        // UTC

  FearGreed({required this.value, required this.classification, required this.timestamp});

  factory FearGreed.fromJson(Map<String, dynamic> j) {
    return FearGreed(
      value: int.parse(j['value']),
      classification: j['value_classification'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(j['timestamp']) * 1000, isUtc: true),
    );
  }
}

class FearGreedService {
  static const _endpoint = 'https://api.alternative.me/fng/?limit=1&format=json';

  static Future<FearGreed> fetchNow() async {
    final res = await http.get(Uri.parse(_endpoint)).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('FNG API 錯誤：${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    final item = (data['data'] as List).first;
    return FearGreed.fromJson(item);
  }
}
