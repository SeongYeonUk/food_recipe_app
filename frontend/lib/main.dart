// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_recipe_app/screens/login_screen.dart';
import 'package:food_recipe_app/screens/main_screen.dart';
import 'package:food_recipe_app/screens/settings_screen.dart';
import 'package:food_recipe_app/screens/signup_screen.dart';
import 'package:food_recipe_app/screens/splash_screen.dart';
import 'package:food_recipe_app/screens/start_screen.dart';
import 'package:food_recipe_app/user/auth_status.dart';
import 'package:food_recipe_app/user/user_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

Future<void> forceLogout() async {
  const storage = FlutterSecureStorage();
  final authStatus = AuthStatus();
  final userModel = UserModel();

  await storage.deleteAll();

  authStatus.logout();
  userModel.clear();

  navigatorKey.currentState?.pushNamedAndRemoveUntil('/start', (route) => false);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Food Recipe App',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/main': (context) => const MainScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      theme: ThemeData(
        primaryColor: const Color(0xFFFFA500), // 예시 Primary Color
        // 다른 테마 설정 추가 가능
      ),
    );
  }
}

