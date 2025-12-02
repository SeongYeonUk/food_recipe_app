import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Screen import
import 'package:food_recipe_app/screens/refrigerator_screen.dart';
import 'package:food_recipe_app/screens/recipe_recommendation_screen.dart';
import 'package:food_recipe_app/screens/recipe_chatbot_screen.dart';
import 'package:food_recipe_app/screens/settings_screen_fixed.dart';
import 'package:food_recipe_app/screens/community_screen.dart'; // 커뮤니티 화면 import

// 임시 화면 위젯은 이제 community_screen.dart에서만 사용되므로 여기서는 삭제해도 됩니다.
// class PlaceholderScreen extends ...

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
    const CommunityScreen(), // [수정] PlaceholderScreen을 CommunityScreen으로 교체
    const RecipeChatbotScreen(),
    const SettingsScreen(),
  ];

  // ... (이하 모든 코드는 기존과 동일합니다) ...

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
    return PopScope(
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
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: '레시피 챗봇'),
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
