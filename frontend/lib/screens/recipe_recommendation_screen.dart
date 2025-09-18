// lib/screens/recipe_recommendation_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';
import 'create_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipeRecommendationScreen extends StatefulWidget {
  const RecipeRecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecipeRecommendationScreen> createState() => _RecipeRecommendationScreenState();
}

class _RecipeRecommendationScreenState extends State<RecipeRecommendationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeViewModel>(context, listen: false).fetchRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("레시피 추천")),
      body: Consumer<RecipeViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: () => viewModel.fetchRecipes(),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildSection(
                      context: context,
                      viewModel: viewModel,
                      title: 'AI 추천 레시피',
                      recipes: viewModel.filteredAiRecipes,
                      isSelectionMode: viewModel.isAiSelectionMode,
                      onToggleSelectionMode: viewModel.toggleAiSelectionMode,
                      isCustomSection: false,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _buildSection(
                      context: context,
                      viewModel: viewModel,
                      title: '나만의 레시피',
                      recipes: viewModel.customRecipes,
                      isSelectionMode: viewModel.isCustomSelectionMode,
                      onToggleSelectionMode: viewModel.toggleCustomSelectionMode,
                      isCustomSection: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required RecipeViewModel viewModel,
    required String title,
    required List<Recipe> recipes,
    required bool isSelectionMode,
    required VoidCallback onToggleSelectionMode,
    required bool isCustomSection,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCustomSection ? Colors.green.shade300 : Colors.blue.shade300, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: onToggleSelectionMode,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelectionMode ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelectionMode ? Icons.close : Icons.add,
                      color: isSelectionMode ? Colors.red : Colors.black54,
                      size: 20,
                    ),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Expanded(
            child: (viewModel.isLoading && recipes.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : (recipes.isEmpty)
                ? Center(child: Text(isCustomSection ? "저장된 레시피가 없습니다." : "추천 레시피가 없습니다.", style: const TextStyle(color: Colors.grey)))
                : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return _RecipeListItem(recipe: recipe, viewModel: viewModel, isSelectionMode: isSelectionMode, isCustomSection: isCustomSection);
              },
            ),
          ),
          if (isSelectionMode || isCustomSection)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildActionButtons(context, viewModel, isSelectionMode, isCustomSection),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, RecipeViewModel viewModel, bool isSelectionMode, bool isCustomSection) {
    if (isCustomSection) { // 나만의 레시피 섹션
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('레시피 만들기', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRecipeScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
          if (isSelectionMode) ...[
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                label: const Text('즐겨찾기 삭제', style: TextStyle(color: Colors.white)),
                onPressed: viewModel.selectedCustomRecipeIds.isNotEmpty ? () => viewModel.deleteCustomRecipes() : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ]
        ],
      );
    } else { // AI 추천 레시피 섹션
      return isSelectionMode
          ? Row(
        children: [
          Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.favorite_border), onPressed: viewModel.selectedAiRecipeIds.isNotEmpty ? () => viewModel.addFavorites() : null, label: const Text('즐겨찾기 추가'))),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('추천 안함'),
              onPressed: viewModel.selectedAiRecipeIds.isNotEmpty ? () => viewModel.blockRecipes() : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            ),
          ),
        ],
      )
          : const SizedBox.shrink();
    }
  }
}

class _RecipeListItem extends StatelessWidget {
  final Recipe recipe;
  final RecipeViewModel viewModel;
  final bool isSelectionMode;
  final bool isCustomSection;

  const _RecipeListItem({required this.recipe, required this.viewModel, required this.isSelectionMode, required this.isCustomSection});

  @override
  Widget build(BuildContext context) {
    final bool isSelected = isCustomSection ? viewModel.selectedCustomRecipeIds.contains(recipe.id) : viewModel.selectedAiRecipeIds.contains(recipe.id);

    return InkWell(
      onTap: () {
        if (isSelectionMode) {
          isCustomSection ? viewModel.selectCustomRecipe(recipe.id) : viewModel.selectAiRecipe(recipe.id);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: viewModel,
                child: RecipeDetailScreen(
                  recipe: recipe,
                  userIngredients: viewModel.userIngredients,
                ),
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.blue : Colors.grey),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // [솔루션] '부연 설명' 없이 '필요 재료'만 보여주던 원래 코드로 복원합니다.
                  Text('필요 재료: ${recipe.ingredients.join(', ')}', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
