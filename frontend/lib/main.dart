// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'viewmodels/refrigerator_viewmodel.dart';
import 'viewmodels/recipe_viewmodel.dart';

import 'common/const/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/start_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'user/auth_status.dart';
import 'user/user_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RefrigeratorViewModel()),
        ChangeNotifierProvider(create: (_) => RecipeViewModel()),
        // 다른 Provider들도 여기에 등록할 수 있습니다.
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> forceLogout() async {
  const storage = FlutterSecureStorage();
  await storage.deleteAll();
  // Provider를 사용한다면 여기서 상태를 초기화 할 수 있습니다.
  // navigatorKey.currentContext?.read<AuthStatus>().logout();
  // navigatorKey.currentContext?.read<UserModel>().clear();
  navigatorKey.currentState?.pushNamedAndRemoveUntil('/start', (route) => false);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Food Recipe App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/main': (context) => const MainScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      theme: AppTheme.theme,
    );
  }
}


