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
    super.key,
    required this.recipe,
    required this.userIngredients,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeViewModel>(
      builder: (context, viewModel, child) {
        final Recipe? currentRecipe = [...viewModel.allAiRecipes, ...viewModel.customRecipes].firstWhereOrNull((r) => r.id == recipe.id);
        if (currentRecipe == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('오류')),
            body: const Center(child: Text('레시피 정보를 불러올 수 없거나 삭제되었습니다.')),
          );
        }
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _CustomSliverAppBar(recipe: currentRecipe),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBorderBox(
                              color: Colors.amber,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currentRecipe.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(currentRecipe.description, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                                  const SizedBox(height: 16),
                                  _InfoCard(recipe: currentRecipe),
                                  const SizedBox(height: 24),
                                  const _SectionHeader(title: '재료'),
                                  _IngredientsList(ingredients: currentRecipe.ingredients, userIngredients: userIngredients),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildBorderBox(
                              color: Colors.deepOrange,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionHeader(title: '만드는 법'),
                                  _InstructionsList(instructions: currentRecipe.instructions),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ReactionButtons(recipe: currentRecipe, viewModel: viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBorderBox({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
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
      return file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image)));
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InfoItem(icon: Icons.timer, text: recipe.cookingTime),
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
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrangeAccent, size: 24),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class _ReactionButtons extends StatelessWidget {
  final Recipe recipe;
  final RecipeViewModel viewModel;
  const _ReactionButtons({required this.recipe, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final likeCount = recipe.likes < 0 ? 0 : recipe.likes;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1.0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            icon: Icon(
              recipe.userReaction == ReactionState.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: recipe.userReaction == ReactionState.liked ? Colors.blue : Colors.grey,
            ),
            label: Text(
              "좋아요 $likeCount",
              style: TextStyle(
                  color: recipe.userReaction == ReactionState.liked ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold
              ),
            ),
            onPressed: () => viewModel.updateReaction(recipe.id, ReactionState.liked),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            icon: Icon(
              recipe.userReaction == ReactionState.disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
              color: recipe.userReaction == ReactionState.disliked ? Colors.red : Colors.grey,
            ),
            label: Text(
              "싫어요",
              style: TextStyle(
                  color: recipe.userReaction == ReactionState.disliked ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.bold
              ),
            ),
            onPressed: () => viewModel.updateReaction(recipe.id, ReactionState.disliked),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
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
