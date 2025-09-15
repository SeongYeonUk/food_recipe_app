// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ViewModel import
import '../viewmodels/refrigerator_viewmodel.dart';
import '../viewmodels/recipe_viewmodel.dart';
import '../viewmodels/statistics_viewmodel.dart';

// Screen import
import './refrigerator_screen.dart';
import './recipe_recommendation_screen.dart';
import './statistics_report_screen.dart';
import './settings_screen.dart';

// 임시 화면 위젯
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title 화면', style: const TextStyle(fontSize: 24))),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = [
    const RefrigeratorScreen(),
    const RecipeRecommendationScreen(),
    const PlaceholderScreen(title: '커뮤니티'),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    } else {
      _showExitDialog();
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('아니오')),
          TextButton(onPressed: () => SystemNavigator.pop(), child: const Text('예')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RefrigeratorViewModel()),
        ChangeNotifierProxyProvider<RefrigeratorViewModel, RecipeViewModel>(
          create: (context) => RecipeViewModel(),
          update: (context, refrigeratorViewModel, recipeViewModel) {
            if (recipeViewModel == null) return RecipeViewModel();
            final userIngredients = refrigeratorViewModel.filteredIngredients.map((e) => e.name).toList();
            recipeViewModel.updateUserIngredients(userIngredients);
            return recipeViewModel;
          },
        ),
        // [핵심 수정] StatisticsViewModel이 RecipeViewModel을 참조하도록 설정
        ChangeNotifierProxyProvider<RecipeViewModel, StatisticsViewModel>(
          create: (context) => StatisticsViewModel(),
          update: (context, recipeViewModel, statisticsViewModel) {
            if (statisticsViewModel == null) return StatisticsViewModel();
            statisticsViewModel.updateAllRecipes(
                [...recipeViewModel.allAiRecipes, ...recipeViewModel.customRecipes]
            );
            statisticsViewModel.setRecipeViewModel(recipeViewModel);
            return statisticsViewModel;
          },
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvoked: _onPopInvoked,
        child: Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: '나의 냉장고'),
              BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: '레시피 추천'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: '커뮤니티'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '통계'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
            ],
            currentIndex: _selectedIndex,
            unselectedItemColor: Colors.grey,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
