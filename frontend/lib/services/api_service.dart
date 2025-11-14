import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:food_recipe_app/screens/community_screen.dart';
import 'package:food_recipe_app/screens/recipe_recommendation_screen.dart';
import 'package:food_recipe_app/screens/refrigerator_screen.dart';
import 'package:food_recipe_app/screens/settings_screen_fixed.dart';
import 'package:food_recipe_app/screens/statistics_report_screen.dart';

import '../models/basic_recipe_item.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = const [
    RefrigeratorScreen(),
    RecipeRecommendationScreen(),
    CommunityScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    } else {
      _showExitDialog();
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('종료'),
        content: const Text('앱을 종료할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: '내 냉장고'),
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
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  static Future<List<BasicRecipeItem>> searchRecipes(String query) async {
    final url = Uri.parse('/community/search?query=');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> recipeList = jsonDecode(utf8.decode(response.bodyBytes));
        return recipeList.map((item) => BasicRecipeItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('API 호출 중 오류 발생: ');
      return [];
    }
  }
}
