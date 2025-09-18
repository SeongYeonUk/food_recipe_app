// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ViewModel import
import 'viewmodels/refrigerator_viewmodel.dart';
import 'viewmodels/recipe_viewmodel.dart';
import 'viewmodels/statistics_viewmodel.dart'; // StatisticsViewModel 임포트

// Screen import
import 'common/const/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/start_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';

// User 관련 import (만약 파일이 있다면)
// import 'user/auth_status.dart';
// import 'user/user_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    // [솔루션] 앱 전체에서 사용할 ViewModel들을 여기에 등록합니다.
    MultiProvider(
      providers: [
        // ChangeNotifierProvider(create: (_) => AuthStatus()), // 필요 시 주석 해제
        // ChangeNotifierProvider(create: (_) => UserModel()),   // 필요 시 주석 해제

        // RefrigeratorViewModel은 독립적이므로 그대로 둡니다.
        ChangeNotifierProvider(create: (_) => RefrigeratorViewModel()),

        // RecipeViewModel은 RefrigeratorViewModel의 변경사항을 알아야 합니다.
        ChangeNotifierProxyProvider<RefrigeratorViewModel, RecipeViewModel>(
          create: (_) => RecipeViewModel(),
          update: (_, refrigeratorViewModel, recipeViewModel) {
            if (recipeViewModel == null) return RecipeViewModel();
            final userIngredients = refrigeratorViewModel.filteredIngredients.map((e) => e.name).toList();
            recipeViewModel.updateUserIngredients(userIngredients);
            return recipeViewModel;
          },
        ),

        // StatisticsViewModel은 RecipeViewModel의 변경사항을 알아야 합니다.
        ChangeNotifierProxyProvider<RecipeViewModel, StatisticsViewModel>(
          create: (_) => StatisticsViewModel(),
          update: (_, recipeViewModel, statisticsViewModel) {
            if (statisticsViewModel == null) return StatisticsViewModel();
            // statisticsViewModel.setRecipeViewModel(recipeViewModel); // ViewModel 내부에서 이미 호출하므로 중복
            return statisticsViewModel;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> forceLogout() async {
  const storage = FlutterSecureStorage();
  await storage.deleteAll();
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

