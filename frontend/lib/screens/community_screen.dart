// lib/screens/community_screen.dart

import 'package:flutter/material.dart';
import 'community/recipe_showcase_screen.dart';
import 'community/recipe_review_screen.dart';

class CommunityDetailScreen extends StatelessWidget {
  final String title;
  const CommunityDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title 화면', style: const TextStyle(fontSize: 24))),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'label': '오늘의 출석', 'color': Colors.red.shade400, 'screen': const CommunityDetailScreen(title: '오늘의 출석')},
      {'label': '식생활 리포트', 'color': Colors.orange.shade500, 'screen': const CommunityDetailScreen(title: '식생활 리포트')},
      {'label': '식재료 공유', 'color': Colors.yellow.shade600, 'screen': const CommunityDetailScreen(title: '식재료 공유')},
      {'label': '식재료 꿀팁', 'color': Colors.lime.shade500, 'screen': const CommunityDetailScreen(title: '식재료 꿀팁')},
      {'label': '레시피 자랑', 'color': Colors.lightGreen.shade500, 'screen': const RecipeShowcaseScreen()},
      {'label': '레시피 후기', 'color': Colors.green.shade400, 'screen': const RecipeReviewScreen()},
      {'label': '오늘의 레시피', 'color': Colors.teal.shade400, 'screen': const CommunityDetailScreen(title: '오늘의 레시피')},
      {'label': '전문가 레시피', 'color': Colors.green.shade800, 'screen': const CommunityDetailScreen(title: '전문가 레시피')},
      {'label': '장보기 추천', 'color': Colors.cyan.shade400, 'screen': const CommunityDetailScreen(title: '장보기 추천')},
      {'label': '챌린지 미션', 'color': Colors.indigo.shade500, 'screen': const CommunityDetailScreen(title: '챌린지 미션')},
      {'label': '냉장고 챗봇', 'color': Colors.purple.shade400, 'screen': const CommunityDetailScreen(title: '냉장고 챗봇')},
      {'label': '배지', 'color': Colors.pink.shade400, 'screen': const CommunityDetailScreen(title: '배지')},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryItem(
                    context,
                    label: category['label'],
                    color: category['color'],
                    onTap: () => _navigateToScreen(context, category['screen']),
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('광고 배너', style: TextStyle(color: Colors.grey))),
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: '재료, 레시피 검색',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.mic),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
