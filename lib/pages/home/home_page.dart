import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/env.dart';
import '../../main.dart';
import '../../widgets/FearGreedCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        FearGreedCard(), // 👈 恐懼與貪婪指數卡片
        SizedBox(height: 16),
        // 這裡以後可以再加其他卡片
      ],
    );
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
}
