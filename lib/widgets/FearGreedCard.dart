import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../core/config/env.dart';

/// Fear & Greed Index Card
class FearGreedCard extends StatefulWidget {
  const FearGreedCard({Key? key}) : super(key: key);

  @override
  State<FearGreedCard> createState() => _FearGreedCardState();
}

class _FearGreedCardState extends State<FearGreedCard> with TickerProviderStateMixin {
  int? indexValue;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    fetchFearGreedIndex();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 抓 Fear & Greed Index API
  Future<void> fetchFearGreedIndex() async {
    try {
      final url = Uri.parse("https://api.alternative.me/fng/");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final value = int.tryParse(data["data"][0]["value"] ?? "50");
        if (value != null) {
          setState(() => indexValue = value);
          // 🔹 依照 FearGreed 值設定 Lottie 播放進度
          final progress = value / 100.0;
          _controller.animateTo(progress, curve: Curves.easeOut);
        }
      } else {
        debugPrint("❌ FearGreed API error: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ FearGreed API exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "恐懼與貪婪指數",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 用新的 Cyan - Purple Gauge.json
            SizedBox(
              height: 200,
              child: Lottie.asset(
                "assets/lottie/Cyan-Purple-Gauge.json",
                controller: _controller,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 數值顯示
            Text(
              indexValue != null ? "$indexValue / 100" : "載入中...",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
