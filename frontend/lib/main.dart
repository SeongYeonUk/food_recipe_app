// frontend/lib/main.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// [추가] Open Food Facts 설정을 위해 SDK를 import 합니다.
import 'package:openfoodfacts/openfoodfacts.dart';

// [수정] 우리가 만든 테마 파일을 import 합니다.
import 'package:food_recipe_app/common/const/app_theme.dart';
// ViewModel import
import 'viewmodels/refrigerator_viewmodel.dart';
import 'viewmodels/recipe_viewmodel.dart';
import 'viewmodels/statistics_viewmodel.dart';
import 'viewmodels/review_viewmodel.dart'; // [솔루션] 새로 만든 ViewModel 임포트

// Screen import
import 'common/const/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/start_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // === Open Food Facts 전역 설정 (필수: User-Agent, 권장: 언어 우선순위) ===
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'food_recipe_app',              // 앱/프로젝트 이름
    url: 'https://example.com',           // 웹사이트 없으면 생략 가능
  );
  OpenFoodAPIConfiguration.globalLanguages = const [
    OpenFoodFactsLanguage.KOREAN,         // 한국어 우선
    OpenFoodFactsLanguage.ENGLISH,        // 영어 폴백
  ];
  // 필요 시 국가 도메인/환경 지정도 가능: OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.SOUTH_KOREA;

  runApp(const MyApp());
  runApp(
    MultiProvider(
      providers: [
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

        // [솔루션] ReviewViewModel을 앱 전체에서 사용할 수 있도록 여기에 등록합니다.
        // ReviewViewModel은 다른 ViewModel에 의존하지 않으므로, 간단한 ChangeNotifierProvider를 사용합니다.
        ChangeNotifierProvider(create: (_) => ReviewViewModel()),
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

