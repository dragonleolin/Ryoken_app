import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/env.dart';
import '../../core/network/api_service.dart';
import '../../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  String _profile = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final api = context.read<ApiService>();
    final resp = await api.profile();
    setState(() => _profile = '${resp.statusCode}: ${resp.body}');
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildDashboard(),
      const Center(child: Text('Markets (預留)')),
      const Center(child: Text('Settings (預留)')),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('RYOKEN.AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.gold),
            onPressed: () => context.read<AuthState>().setToken(null),
          ),
        ],
      ),
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首頁'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: '市場'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('歡迎回來', style: TextStyle(fontSize: 22, color: AppColors.gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Profile API 回應（示例）：\n$_profile'),
        ],
      ),
    );
  }
}
