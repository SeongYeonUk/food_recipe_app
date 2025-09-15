// lib/screens/recipe_detail_screen.dart

import 'dart:io';
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
                      Text(currentRecipe.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _InfoCard(recipe: currentRecipe),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: '재료'),
                      _IngredientsList(ingredients: currentRecipe.ingredients, userIngredients: userIngredients),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: '만드는 법'),
                      _InstructionsList(instructions: currentRecipe.instructions),
                      const SizedBox(height: 32),
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
        background: _buildBackgroundImage(),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final imageUrl = recipe.imageUrl;
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.no_photography))),
      );
    } else {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      } else {
        return Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image)));
      }
    }
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
            _InfoItem(icon: Icons.timer, text: '${recipe.cookingTime}'),
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
        final bool hasIngredient = userIngredients.any((userIng) => coreIngredient.contains(userIng));
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


