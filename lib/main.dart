import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/env.dart';
import 'core/storage/token_storage.dart';
import 'core/network/api_service.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final env = AppEnv.fromDefine();
  runApp(RyokenApp(env: env));
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
  final AppEnv env;
  const RyokenApp({super.key, required this.env});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..load()),
        Provider(create: (_) => ApiService(env)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RYOKEN.AI',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.black,
          primaryColor: AppColors.gold,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            secondary: AppColors.gold,
            surface: AppColors.black,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF111111),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gold, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gold, width: 2),
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            checkColor: WidgetStateProperty.all(Colors.black),
            fillColor: WidgetStateProperty.all(AppColors.gold),
            side: const BorderSide(color: AppColors.gold),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        home: const RootGate(),
      ),
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
