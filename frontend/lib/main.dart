import 'package:flutter/material.dart';
import 'package:food_recipe_app/services/calendar_client.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:food_recipe_app/services/home_geofence.dart';
// ViewModel import
import 'viewmodels/refrigerator_viewmodel.dart';
import 'viewmodels/recipe_viewmodel.dart';
import 'viewmodels/statistics_viewmodel.dart';
import 'viewmodels/review_viewmodel.dart';

// Screen import
import 'common/const/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/start_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await HomeGeofence.initialize();
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
        ChangeNotifierProvider(create: (_) => RefrigeratorViewModel()),
        ChangeNotifierProxyProvider<RefrigeratorViewModel, RecipeViewModel>(
          create: (_) => RecipeViewModel(),
          update: (_, refrigeratorViewModel, recipeViewModel) {
            if (recipeViewModel == null) return RecipeViewModel();
            final userIngredients = refrigeratorViewModel.ingredients.map((e) => e.name).toList();
            recipeViewModel.updateUserIngredients(userIngredients);
            return recipeViewModel;
          },
          lazy: false,
        ),
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
