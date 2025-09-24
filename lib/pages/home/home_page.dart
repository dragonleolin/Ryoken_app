import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/env.dart';
import '../../core/network/api_service.dart';
import '../subscription_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedTf = "5m"; // 預設 timeframe
  String selectedSymbol = "BTCUSDT"; // 預設幣種
  String selectedInvestmentType = "Balanced"; // 預設 Balanced
  bool autoUpdate = true;
  bool isPaidMember = false;
  // 🔹 動態顯示的幣種清單（初始化成 allCoins）
  List<Map<String, dynamic>> coins = [];

  List<String> alerts = [];
  Map<String, dynamic> apiData = {};
  // 全部 12 種幣種
  final List<Map<String, dynamic>> allCoins  = [
    {"symbol": "BTC", "value": 0.0},
    {"symbol": "ETH", "value": 0.0},
    {"symbol": "SOL", "value": 0.0},
    {"symbol": "BNB", "value": 0.0},
    {"symbol": "XRP", "value": 0.0},
    {"symbol": "ADA", "value": 0.0},
    {"symbol": "DOGE", "value": 0.0},
    {"symbol": "AVAX", "value": 0.0},
    {"symbol": "DOT", "value": 0.0},
    {"symbol": "LINK", "value": 0.0},
    {"symbol": "MATIC", "value": 0.0},
    {"symbol": "TON", "value": 0.0},
  ];

  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchMembershipAndData();

    // alerts 輪播
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && alerts.isNotEmpty) {
        _currentPage = (_currentPage + 1) % alerts.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 🚀 一次處理 membership + homepage API
  Future<void> _fetchMembershipAndData() async {
    try {
      // 1. Membership API
      final membershipRes = await ApiService.fetchMembership(selectedTf);

      setState(() {
        isPaidMember = membershipRes["paidMember"] ?? false;

        final available = List<Map<String, dynamic>>.from(membershipRes["coins"]);
        print("✅ available=$available");
        if (isPaidMember) {
          // ✅ 會員直接用 API 的完整清單
          coins = available;
        } else {
          // ❌ 非會員：只回傳 4 種，手動補滿成 12 種
          coins = allCoins.map((c) {
            final found = available.firstWhere(
                  (a) => a["symbol"] == c["symbol"],
              orElse: () => {},
            );

            // 如果有 API 資料 → 用 API value，否則 value 設為 null
            return found.isNotEmpty
                ? {"symbol": found["symbol"], "value": found["value"]}
                : {"symbol": c["symbol"], "value": null};
          }).toList();
          print("✅ coins=$coins");
        }
      });

      // 2. Homepage API
      final dataRes = await ApiService.fetchHomePageData(
        cryptocurrency: selectedSymbol,
        timeframe: selectedTf,
        investmentType: selectedInvestmentType.toLowerCase(),
      );
      setState(() {
        apiData = dataRes;
        alerts = List<String>.from(dataRes["alerts"] ?? []);
      });
    } catch (e) {
      debugPrint("❌ API Error: $e");
    }
  }

  void _manualRefresh() {
    debugPrint("手動刷新數據...");
    _fetchMembershipAndData();
  }

  // ========================== UI ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          "RYOKEN-AI ｜ 市場趨勢與情資",
          style: TextStyle(color: AppColors.gold, fontSize: 18),
        ),
        actions: [
          DropdownButton<String>(
            value: selectedTf,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            underline: const SizedBox(),
            items: ["5m", "15m", "1h", "4h", "1d"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => selectedTf = v);
                _fetchMembershipAndData();
              }
            },
          ),
          TextButton(
            onPressed: _manualRefresh,
            child: const Text("手動刷新", style: TextStyle(color: AppColors.gold)),
          ),
          Row(
            children: [
              const Text("自動更新",
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              Switch(
                value: autoUpdate,
                onChanged: (v) => setState(() => autoUpdate = v),
                activeColor: AppColors.gold,
              )
            ],
          )
        ],
      ),
      body: apiData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 即時告警 =================
            if (alerts.isNotEmpty)
              SizedBox(
                height: 40,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Text(
                        alerts[index],
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // ================= 幣種清單 =================
            const Text(
              "幣種清單（點擊切換分析）",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(coins.length, (index) {
                final coin = coins[index];
                final locked = !isPaidMember && index >= 4; // 非會員 -> 後 8 種鎖住

                return GestureDetector(
                  onTap: locked
                      ? () {
                    // 🔒 非會員點鎖住的幣 -> 彈出提示
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: const Text("功能限制", style: TextStyle(color: AppColors.gold)),
                        content: const Text("升級會員即可解鎖更多幣種！",
                            style: TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("取消", style: TextStyle(color: AppColors.muted)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                              );
                            },
                            child: const Text("升級會員"),
                          ),
                        ],
                      ),
                    );
                  }
                      : () {
                    setState(() => selectedSymbol = "${coin["symbol"]}USDT");
                    _fetchMembershipAndData();
                  },
                  child: Opacity(
                    opacity: locked ? 0.5 : 1, // 🔹 鎖住的幣種半透明
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedSymbol == "${coin["symbol"]}USDT"
                              ? AppColors.gold
                              : AppColors.muted,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            coin["symbol"],
                            style: const TextStyle(
                                color: AppColors.gold, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("USDT",
                                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
                              const SizedBox(width: 4),
                              locked
                                  ? const Icon(Icons.lock, color: AppColors.muted, size: 14)
                                  : Text(
                                coin["value"]?.toString() ?? "--",  // null → 顯示 --
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // ================= 幣種標題 =================
            Row(
              children: [
                Text(
                  "$selectedSymbol · $selectedTf",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.circle, size: 10, color: Colors.green),
                const SizedBox(width: 4),
                const Text("上升趨勢",
                    style: TextStyle(color: Colors.green, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),

            // ================= 建議卡片 =================
            _RecommendationCard(data: apiData["recommendation"], trend: apiData["trendDetails"]),

            const SizedBox(height: 16),

            // ================= TrendScore + 多時框 + 指標 =================
            _TrendScoreBlock(
              data: apiData["trendScore"],
              selected: selectedInvestmentType,
              onChanged: (opt) {
                setState(() => selectedInvestmentType = opt);
                _fetchMembershipAndData();
              },
            ),
            const SizedBox(height: 16),

            // ================= Text Notes =================
            _TextNotesBlock(notes: List<String>.from(apiData["trendScore"]["textNotes"] ?? [])),
            const SizedBox(height: 24),

            // ================= Market Intel =================
            _MarketIntelBlock(data: apiData["marketIntel"]),
            const SizedBox(height: 24),

            // ================= HIGHLIGHTS =================
            _HighlightsBlock(highlights: List<String>.from(apiData["highlights"] ?? [])),
            const SizedBox(height: 24),

            // ================= 市場廣度 =================
            _BreadthBlock(data: apiData["breadth"]),
            const SizedBox(height: 24),

            // ================= 策略註記 =================
            _StrategyNotesBlock(notes: List<String>.from(apiData["strategyNotes"] ?? [])),
            const SizedBox(height: 24),

            // ================= Footer =================
            const Center(
              child: Text(
                "視覺為示意 Demo：真實數據將由 backend/ 提供 API 並每隔數秒更新",
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 建議卡片 =================
class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List trend;

  const _RecommendationCard({required this.data, required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade400, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "建議：${data["action"]}   信心 ${(data["confidence"] * 100).toStringAsFixed(1)}%   風險 ${data["risk"]}",
            style: const TextStyle(color: Colors.green, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...trend.map((t) => Text("• $t",
              style: const TextStyle(color: Colors.white, fontSize: 14))),
          const SizedBox(height: 6),
          const Text("* 僅供教育用途，非投資建議。",
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ================= TrendScore 區塊 =================
class _TrendScoreBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  final String selected;
  final Function(String) onChanged;

  const _TrendScoreBlock(
      {required this.data, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final score = data["score"] ?? 0;
    final indicators = data["indicators"] ?? {};
    final options = ["Aggressive", "Conservative", "Balanced"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // TrendScore 圓環
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
              Text(
                "$score",
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("TrendScore",
              style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 16),

          // MultiTimeFrame
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: options.map((opt) {
              final isActive = selected == opt;
              return GestureDetector(
                onTap: () => onChanged(opt),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isActive ? AppColors.gold : Colors.grey.shade700,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.card,
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: isActive ? AppColors.gold : Colors.white70,
                      fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 指標
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCard(title: "ADX14", value: "${indicators["ADX14"]}", sub: "趨勢強度"),
              _StatCard(title: "RSI14", value: "${indicators["RSI14"]}", sub: "動能"),
              _StatCard(title: "ATRz", value: "${indicators["ATRz"]}", sub: "波動"),
              _StatCard(
                title: "EMA20/50/200",
                value:
                "${indicators["EMA20"]} / ${indicators["EMA50"]} / ${indicators["EMA200"]}",
                sub: "短/中/長",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= Stat 小卡 =================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;

  const _StatCard({required this.title, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ================= _KpiCard =================
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String hint;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(hint,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
// ================= HIGHLIGHTS =================
class _HighlightsBlock extends StatelessWidget {
  final List<String> highlights;
  const _HighlightsBlock({required this.highlights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("HIGHLIGHTS",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...highlights.map((h) => Text("• $h",
              style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}

// ================= TextNotes =================
class _TextNotesBlock extends StatelessWidget {
  final List<String> notes;
  const _TextNotesBlock({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notes
            .map((note) =>
            Text("• $note", style: const TextStyle(color: Colors.white)))
            .toList(),
      ),
    );
  }
}

// ================= Market Intel =================
class _MarketIntelBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MarketIntelBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Market Intel",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // 三列，每列兩張卡片
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                      title: "Funding(8h)",
                      value: data["funding8h"],
                      hint: data["fundingHint"])),
              const SizedBox(width: 8),
              Expanded(
                  child: _KpiCard(
                      title: "OI 24h",
                      value: data["oi24h"],
                      hint: data["oiHint"])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                      title: "ETF 淨流(1d)",
                      value: data["etfFlow"],
                      hint: data["etfHint"])),
              const SizedBox(width: 8),
              Expanded(
                  child: _KpiCard(
                      title: "點差 / 深度",
                      value: data["spread"],
                      hint: data["spreadHint"])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                      title: "Fear&Greed",
                      value: data["fearGreed"],
                      hint: data["fearGreedHint"])),
              const SizedBox(width: 8),
              Expanded(
                  child: _KpiCard(
                      title: "DXY 5d",
                      value: data["dxy5d"],
                      hint: data["dxyHint"])),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= 市場廣度 =================
class _BreadthBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BreadthBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("市場廣度 (Crypto Top50)",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // 三張小卡片（Row + Expanded）
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: "RiskIndex",
                  value: "${data["riskIndex"]}",
                  hint: "0-100 中性50",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  title: "% > EMA50",
                  value: "+${data["ema50Percent"]}%",
                  hint: "上方占比",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  title: "A/D",
                  value: "${data["ad"]}",
                  hint: "漲家 / 跌家",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 註解文字
          Text(data["note"] ?? "",
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

// ================= 策略註記 =================
class _StrategyNotesBlock extends StatelessWidget {
  final List<String> notes;
  const _StrategyNotesBlock({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("策略註記",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...notes.map((n) => Text("• $n",
              style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}