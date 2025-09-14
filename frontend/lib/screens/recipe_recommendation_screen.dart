// lib/screens/recipe_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';
import './create_recipe_screen.dart';
import './recipe_detail_screen.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(title: const Text("레시피 추천")),
          body: viewModel.isLoading && viewModel.customRecipes.isEmpty && viewModel.allAiRecipes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Expanded(
                child: _RecipeSection(
                  title: 'AI 추천 레시피',
                  recipes: viewModel.filteredAiRecipes,
                  isSelectionMode: viewModel.isAiSelectionMode,
                  selectedRecipeIds: viewModel.selectedAiRecipeIds,
                  onToggleSelectionMode: viewModel.toggleAiSelectionMode,
                  onSelectRecipe: viewModel.selectAiRecipe, // [수정] int를 받는 메소드로 바로 연결
                  buttons: viewModel.isAiSelectionMode ? [
                    Expanded(child: ElevatedButton(onPressed: viewModel.selectedAiRecipeIds.isEmpty ? null : viewModel.addFavorites, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), child: const Text('즐겨찾기 추가'))),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(onPressed: viewModel.selectedAiRecipeIds.isEmpty ? null : viewModel.blockRecipes, style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300), child: const Text('추천 안함'))),
                  ] : [],
                ),
              ),
              Expanded(
                child: _RecipeSection(
                  title: '나만의 레시피',
                  recipes: viewModel.customRecipes,
                  isSelectionMode: viewModel.isCustomSelectionMode,
                  selectedRecipeIds: viewModel.selectedCustomRecipeIds,
                  onToggleSelectionMode: viewModel.toggleCustomSelectionMode,
                  onSelectRecipe: viewModel.selectCustomRecipe, // [수정] int를 받는 메소드로 바로 연결
                  buttons: viewModel.isCustomSelectionMode ? [
                    Expanded(child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: viewModel, child: const CreateRecipeScreen())));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade300),
                      child: const Text('레시피 만들기'),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(onPressed: viewModel.selectedCustomRecipeIds.isEmpty ? null : viewModel.deleteCustomRecipes, style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300), child: const Text('즐겨찾기 삭제'))),
                  ] : [],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecipeSection extends StatelessWidget {
  final String title;
  final List<Recipe> recipes;
  final bool isSelectionMode;
  final Set<int> selectedRecipeIds; // [수정] Set<String> -> Set<int>
  final VoidCallback onToggleSelectionMode;
  final ValueChanged<int> onSelectRecipe; // [수정] ValueChanged<String> -> ValueChanged<int>
  final List<Widget> buttons;

  const _RecipeSection({
    required this.title,
    required this.recipes,
    required this.isSelectionMode,
    required this.selectedRecipeIds,
    required this.onToggleSelectionMode,
    required this.onSelectRecipe,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0).copyWith(bottom: 8.0),
      decoration: BoxDecoration(border: Border.all(color: title == 'AI 추천 레시피' ? Colors.blueAccent : Colors.green, width: 1.5), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: Icon(isSelectionMode ? Icons.close : Icons.add_circle, size: 28), onPressed: onToggleSelectionMode),
              ],
            ),
          ),
          Expanded(
            child: recipes.isEmpty
                ? Center(child: Text(title == 'AI 추천 레시피' ? "보유한 재료로 만들 수 있는\n추천 레시피가 없습니다." : "저장된 레시피가 없습니다.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return _RecipeItem(recipe: recipe, isSelectionMode: isSelectionMode, isSelected: selectedRecipeIds.contains(recipe.id), onSelected: () => onSelectRecipe(recipe.id));
              },
            ),
          ),
          if (buttons.isNotEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0), child: Row(children: buttons)),
        ],
      ),
    );
  }
}

class _RecipeItem extends StatelessWidget {
  final Recipe recipe;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelected;

  const _RecipeItem({
    required this.recipe,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final userIngredients = Provider.of<RecipeViewModel>(context, listen: false).userIngredients;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: isSelectionMode ? onSelected : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: Provider.of<RecipeViewModel>(context, listen: false),
                child: RecipeDetailScreen(
                  recipe: recipe,
                  userIngredients: userIngredients,
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              if (isSelectionMode)
                Checkbox(value: isSelected, onChanged: (_) => onSelected, visualDensity: VisualDensity.compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('필요 재료: ${recipe.ingredients.join(', ')}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
