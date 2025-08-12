// frontend/lib/main.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// [수정] 우리가 만든 테마 파일을 import 합니다.
import 'package:food_recipe_app/common/const/app_theme.dart';

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
      debugShowCheckedModeBanner: false, // 디버그 배너 숨기기
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/main': (context) => const MainScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      // [수정] 직접 정의하던 테마 대신, app_theme.dart의 테마를 사용합니다.
      theme: AppTheme.theme,
    );
  }
}

