import 'package:flutter/material.dart';

class RecipeRecommendationScreen extends StatelessWidget {
  const RecipeRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 샘플 데이터
    final List<Map<String, String>> _recipes = [
      {'name': '계란 양파 볶음밥', 'ingredients': '계란, 양파, 밥'},
      {'name': '어니언 스프', 'ingredients': '양파, 우유'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 레시피'),
      ),
      body: ListView.builder(
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(recipe['name']!),
              subtitle: Text('필요 재료: ${recipe['ingredients']}'),
              onTap: () {
                // TODO: 레시피 상세 정보 화면으로 이동
              },
            ),
          );
        },
      ),
    );
  }
}
