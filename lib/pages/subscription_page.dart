import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../core/config/env.dart';
import '../../core/network/api_service.dart'; // 🔹 你專案的 ApiService
import 'home/home_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String? currentPlan;
  List<Map<String, dynamic>> plans = [];

  int? selectedPlanId;
  String selectedPayment = "credit"; // 預設付款方式

  final List<Map<String, String>> paymentMethods = [
    {"id": "credit", "name": "信用卡"},
    {"id": "googlePay", "name": "Google Pay"},
    {"id": "applePay", "name": "Apple Pay"},
  ];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final data = await ApiService.fetchPlans();
      setState(() {
        currentPlan = data["currentPlan"];
        plans = data["plans"];
      });
    } catch (e) {
      debugPrint("❌ _loadPlans error: $e");
    }
  }

  Future<void> _upgradePlan() async {
    try {

      if (selectedPayment == "credit") {
        // ✅ 信用卡 → 呼叫後端建立 PaymentIntent
        final intent = await ApiService.createPaymentIntent(selectedPlanId!);
        //final clientSecret = intent["clientSecret"];
        print("✅ intent: ${intent}");
        // 初始化付款介面
        // await Stripe.instance.initPaymentSheet(
        //   paymentSheetParameters: SetupPaymentSheetParameters(
        //     paymentIntentClientSecret: clientSecret,
        //     style: ThemeMode.dark,
        //     merchantDisplayName: "Ryoken AI",
        //   ),
        // );
        //
        // // 顯示 Stripe 付款 UI
        // await Stripe.instance.presentPaymentSheet();

        if (intent.isNotEmpty) {
          await ApiService.confirmPayment(
            paymentIntentId: intent["paymentIntentId"] as int, // ✅ 明確轉成 int
            planId: selectedPlanId!,
          );

          _showDialog("升級成功 🎉", "方案已升級為 $selectedPlanId");
        } else {
          _showDialog("錯誤", "無法完成付款，請稍後再試");
        }

      } else if (selectedPayment == "applePay" || selectedPayment == "googlePay") {
        // ✅ Apple Pay / Google Pay → 不需先建立 PaymentIntent，直接呼叫 Stripe PaymentSheet
        print("✅ Apple Pay / Google Pay");
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            merchantDisplayName: "Ryoken AI",
            style: ThemeMode.dark,
            applePay: selectedPayment == "applePay"
                ? const PaymentSheetApplePay(merchantCountryCode: 'TW')
                : null,
            googlePay: selectedPayment == "googlePay"
                ? const PaymentSheetGooglePay(
              merchantCountryCode: 'TW',
              currencyCode: 'TWD',
              testEnv: true,
            )
                : null,
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        // ✅ 付款完成後通知後端
        await ApiService.confirmPayment(
          paymentIntentId: selectedPlanId!,
          planId: selectedPlanId!,
        );
        _showDialog("升級成功 🎉", "已透過 ${selectedPayment == "applepay" ? "Apple Pay" : "Google Pay"} 完成付款");
      }

    } on StripeException catch (e) {
      debugPrint("❌ Stripe 錯誤: $e");
      _showDialog("付款失敗", "Stripe 錯誤: ${e.error.localizedMessage}");
    } catch (e) {
      debugPrint("❌ 升級失敗: $e");
      _showDialog("錯誤", "無法完成付款，請稍後再試");
    }
  }


  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: const TextStyle(color: AppColors.gold)),
        content: Text(message, style: const TextStyle(color: AppColors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("確定", style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("訂閱方案", style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.bg,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gold),
        // 🔹 右上角的叉叉關閉按鈕
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.gold),
            onPressed: () {
              setState(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              });
            },
          ),
        ],
      ),
      body: plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (currentPlan != null) ...[
              Text("目前方案：$currentPlan",
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ],

            const Text("解鎖更多策略訊號與高階分析工具",
                style: TextStyle(color: AppColors.white70, fontSize: 14)),
            const SizedBox(height: 16),

            // 🔹 方案清單
            Expanded(
              child: ListView.separated(
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isSelected = selectedPlanId == plan["id"];

                  return GestureDetector(
                    onTap: () => setState(() => selectedPlanId = plan["id"] as int),
                    child: _PlanCard(
                      title: plan["title"] ?? "",
                      label: plan["priceLabel"] ?? "",
                      price: plan["price"] ?? "",
                      features: (plan["features"] as List).cast<String>(),
                      isSelected: isSelected,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 付款方式選取
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: paymentMethods.map((pm) {
                  final isActive = selectedPayment == pm["id"];
                  return ChoiceChip(
                    label: Text(pm["name"]!),
                    selected: isActive,
                    onSelected: (_) => setState(() {
                      selectedPayment = pm["id"]!;
                    }),
                    selectedColor: AppColors.gold,
                    labelStyle: TextStyle(
                      color: isActive ? AppColors.bg : AppColors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 升級按鈕
            ElevatedButton(
              onPressed: _upgradePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 60, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("立即升級",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ================== 方案卡片 ==================
class _PlanCard extends StatelessWidget {
  final String title;
  final String label;
  final String price;
  final List<String> features;
  final bool isSelected;

  const _PlanCard({
    required this.title,
    required this.label,
    required this.price,
    required this.features,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.gold : AppColors.muted,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: AppColors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            price == 0 ? "免費" : "\$${price}/月",
            style: const TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features
                .map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check,
                      color: AppColors.gold, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(f,
                          style: const TextStyle(
                              color: AppColors.white70, fontSize: 14))),
                ],
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}