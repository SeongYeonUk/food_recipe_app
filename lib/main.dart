import 'package:flutter/material.dart';
import 'package:food_recipe_app/screens/splash_screen.dart';
import '../../../../food_recipe_app/lib/screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/signup_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1인 가구 식재료 관리 앱',
      theme: ThemeData(
        fontFamily: 'NotoSans',
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 초기 라우트를 로그인 화면으로 설정합니다.
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}