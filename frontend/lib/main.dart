import 'package:flutter/material.dart';
// [수정] 모든 import를 'package:'로 시작하는 절대 경로 방식으로 통일합니다.
import 'package:food_recipe_app/screens/splash_screen.dart';
import 'package:food_recipe_app/screens/start_screen.dart';
import 'package:food_recipe_app/screens/login_screen.dart';
import 'package:food_recipe_app/screens/main_screen.dart';
import 'package:food_recipe_app/screens/signup_screen.dart';

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
        primarySwatch: Colors.green, // Colors.green은 primarySwatch에 사용할 수 있습니다.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}
