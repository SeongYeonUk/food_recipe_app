// lib/screens/main_screen.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:food_recipe_app/screens/refrigerator_screen.dart';
import 'package:food_recipe_app/screens/settings_screen.dart';

// 아직 만들지 않은 화면들을 위한 임시 위젯 (오류 방지용)
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
    const RefrigeratorScreen(), // 첫 번째 탭은 '나의 냉장고' 화면
    const PlaceholderScreen(title: '레시피 추천'), // 두 번째 탭은 임시 화면
    const PlaceholderScreen(title: '통계'), // 세 번째 탭은 임시 화면
    const SettingsScreen(), // 네 번째 탭은 설정 화면
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text('예'),
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
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.kitchen),
              label: '나의 냉장고',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: '레시피 추천',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: '통계',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
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

