// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Screen import
import './refrigerator_screen.dart';
import './recipe_recommendation_screen.dart';
import './statistics_report_screen.dart'; // statistics_report_screen.dart -> statistics_screen.dart
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

  // [솔루션] statistics_report_screen -> statistics_screen.dart로 변경
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
    // [솔루션] Provider 설정은 main.dart로 이동했으므로, 여기서는 UI만 그립니다.
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


