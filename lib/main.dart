import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ryoken_app/pages/splash_screen.dart';
import 'core/config/env.dart';
import 'core/network/api_service.dart';
import 'core/storage/token_storage.dart';
import 'pages/auth/login_page.dart';
import 'pages/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final env = AppEnv.fromDefine();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..load()),
        Provider(create: (_) => env),
        Provider(create: (_) => ApiService()), // 🔹 確保 ApiService 也在這裡
      ],
      child: const RyokenApp(),
    ),
  );
}

class AuthState extends ChangeNotifier {
  String? _token;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> load() async {
    _token = await TokenStorage.readToken();
    notifyListeners();
  }

  Future<void> setToken(String? token) async {
    _token = token;
    if (token == null) {
      await TokenStorage.clear();
    } else {
      await TokenStorage.saveToken(token);
    }
    notifyListeners();
  }
}

class RyokenApp extends StatelessWidget {
  const RyokenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RYOKEN.AI',
      theme: ThemeData.dark(),
      home: const RootGate(),
      routes: {
        "/login": (context) => const LoginPage(),
        "/home": (context) => const HomePage(),
      },
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (_, auth, __) {
        if (auth.isLoggedIn) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}