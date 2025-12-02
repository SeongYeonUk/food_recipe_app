import 'package:flutter/material.dart';
import 'package:food_recipe_app/services/calendar_client.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

// --- ⬇️ [핵심] 모든 import를 절대 경로로 수정 ⬇️ ---
import 'package:food_recipe_app/services/home_geofence.dart';
import 'package:food_recipe_app/services/notification_service.dart';
// ViewModel import
import 'package:food_recipe_app/viewmodels/refrigerator_viewmodel.dart';
import 'package:food_recipe_app/viewmodels/recipe_viewmodel.dart';
import 'package:food_recipe_app/viewmodels/statistics_viewmodel.dart';
import 'package:food_recipe_app/viewmodels/review_viewmodel.dart';

// Screen import
import 'package:food_recipe_app/common/const/app_theme.dart';
import 'package:food_recipe_app/screens/splash_screen.dart';
import 'package:food_recipe_app/screens/start_screen.dart';
import 'package:food_recipe_app/screens/login_screen.dart';
import 'package:food_recipe_app/screens/signup_screen.dart';
import 'package:food_recipe_app/screens/main_screen.dart';
import 'package:food_recipe_app/screens/settings_screen_fixed.dart';
// --- ⬆️ import 수정 완료 ⬆️ ---

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await HomeGeofence.initialize();
  // Sync user's saved home location from backend
  await HomeGeofence.syncHomeFromServer();
  // Ensure background daily notification worker is scheduled
  await NotificationService.ensureScheduledBackground();
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'food_recipe_app',
    url: 'https://example.com',
  );
  OpenFoodAPIConfiguration.globalLanguages = const [
    OpenFoodFactsLanguage.KOREAN,
    OpenFoodFactsLanguage.ENGLISH,
  ];

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarClient()),

        // 1. [순서 중요] RefrigeratorViewModel이 ProxyProvider보다 먼저 정의되어야 합니다.
        ChangeNotifierProvider(create: (_) => RefrigeratorViewModel()),

        // 2. [❗️핵심 수정] RecipeViewModel이 RefrigeratorViewModel을 "구독"합니다.
        ChangeNotifierProxyProvider<RefrigeratorViewModel, RecipeViewModel>(
          create: (_) => RecipeViewModel(),

          // [❗️핵심 수정]
          // RefrigeratorViewModel이 변경될 때 (예: 재료 로딩 완료, 재료 추가/삭제)
          // RecipeViewModel의 updateUserIngredients 함수를 호출합니다.
          update: (_, refrigeratorViewModel, recipeViewModel) {
            if (recipeViewModel == null) return RecipeViewModel();

            // 1. RefrigeratorViewModel에서 '전체 재료 목록 (List<Ingredient>)'을 가져옵니다.
            final newIngredients = refrigeratorViewModel.userIngredients;

            // 2. RecipeViewModel에 최신 재료 목록을 전달하여 AI 추천을 재계산시킵니다.
            recipeViewModel.updateUserIngredients(newIngredients);

            return recipeViewModel;
          },
          lazy: false,
        ),

        // 3. StatisticsViewModel (기존 코드 유지)
        ChangeNotifierProxyProvider<RecipeViewModel, StatisticsViewModel>(
          create: (_) => StatisticsViewModel(),
          update: (_, recipeViewModel, statisticsViewModel) {
            if (statisticsViewModel == null) return StatisticsViewModel();
            return statisticsViewModel;
          },
        ),

        ChangeNotifierProvider(create: (_) => ReviewViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> forceLogout() async {
  // ▼▼▼ [핵심 수정] 클래스 이름의 오타를 수정했습니다. (FlutterSecure_storage -> FlutterSecureStorage) ▼▼▼
  const storage = FlutterSecureStorage();
  // ▲▲▲ 여기까지 ▲▲▲
  await storage.deleteAll();
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    '/start',
        (route) => false,
  );
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
      // (const가 제거된 routes 맵)
      routes: {
        '/': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/main': (context) => MainScreen(),
        '/settings': (context) => SettingsScreen(),
      },
      theme: AppTheme.theme,
    );
  }
}
