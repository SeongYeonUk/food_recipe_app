// lib/screens/recipe_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final List<String> userIngredients;

  const RecipeDetailScreen({
    Key? key,
    required this.recipe,
    required this.userIngredients,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeViewModel>(
      builder: (context, viewModel, child) {
        final Recipe? currentRecipe = [...viewModel.allAiRecipes, ...viewModel.customRecipes]
            .firstWhereOrNull((r) => r.id == recipe.id);

        if (currentRecipe == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('오류')),
            body: const Center(child: Text('레시피 정보를 불러올 수 없거나 삭제되었습니다.')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _CustomSliverAppBar(recipe: currentRecipe),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoCard(recipe: currentRecipe),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: '재료'),
                      _IngredientsList(
                        ingredients: currentRecipe.ingredients,
                        userIngredients: userIngredients,
                      ),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: '만드는 법'),
                      _InstructionsList(instructions: currentRecipe.instructions),
                      const SizedBox(height: 32),
                      // TODO: 좋아요/싫어요 API 연동 필요
                      // _ReactionButtons(recipe: currentRecipe),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomSliverAppBar extends StatelessWidget {
  final Recipe recipe;
  const _CustomSliverAppBar({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(recipe.name, style: const TextStyle(shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
        // [핵심 수정] Image.asset -> Image.network
        background: Image.network(
          recipe.imageUrl,
          fit: BoxFit.cover,
          // 이미지를 불러오는 동안 로딩 인디케이터 표시
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          // 이미지 로드 실패 시 에러 아이콘 표시
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.no_photography, color: Colors.grey, size: 50)));
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Recipe recipe;
  const _InfoCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // [핵심 수정] int 타입의 cookingTime을 문자열로 변환하여 표시
            _InfoItem(icon: Icons.timer, text: '${recipe.cookingTime} 분'),
            _InfoItem(icon: Icons.favorite, text: '${recipe.likes} Likes'),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepOrangeAccent, size: 30),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final List<String> ingredients;
  final List<String> userIngredients;
  const _IngredientsList({required this.ingredients, required this.userIngredients});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ingredients.map((recipeIngredient) {
        final coreIngredient = recipeIngredient.split(' ')[0];
        final bool hasIngredient = userIngredients.contains(coreIngredient);
        return ListTile(
          leading: Icon(hasIngredient ? Icons.check_circle : Icons.remove_circle_outline, color: hasIngredient ? Colors.green : Colors.grey),
          title: Text(recipeIngredient, style: TextStyle(color: hasIngredient ? Colors.black : Colors.grey, decoration: hasIngredient ? TextDecoration.none : TextDecoration.lineThrough)),
        );
      }).toList(),
    );
  }
}

class _InstructionsList extends StatelessWidget {
  final List<String> instructions;
  const _InstructionsList({required this.instructions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < instructions.length; i++)
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.deepOrangeAccent, child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
            title: Text(instructions[i], style: const TextStyle(height: 1.4)),
          ),
      ],
    );
  }
}

