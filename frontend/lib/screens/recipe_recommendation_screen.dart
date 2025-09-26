// lib/screens/recipe_recommendation_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';
import 'create_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipeRecommendationScreen extends StatefulWidget {
  const RecipeRecommendationScreen({super.key});

  @override
  State<RecipeRecommendationScreen> createState() => _RecipeRecommendationScreenState();
}

class _RecipeRecommendationScreenState extends State<RecipeRecommendationScreen> {
  // [솔루션] 현재 확장된 섹션을 추적하기 위한 상태 변수
  String _expandedSection = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeViewModel>(context, listen: false).fetchRecipes();
    });
  }

  // [솔루션] 섹션 제목을 탭했을 때 호출될 함수
  void _toggleSection(String sectionName) {
    setState(() {
      if (_expandedSection == sectionName) {
        _expandedSection = ''; // 이미 열려있으면 닫기
      } else {
        _expandedSection = sectionName; // 다른 섹션을 열기
      }
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
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- 1. AI 추천 레시피 섹션 ---
                _buildAiSection(context, viewModel),
                const SizedBox(height: 16),

                // --- 2. 나만의 레시피 섹션 ---
                _buildCollapsibleSection(
                  context: context,
                  viewModel: viewModel,
                  title: '나만의 레시피',
                  recipes: viewModel.myRecipes,
                  isExpanded: _expandedSection == 'my',
                  isSelectionMode: viewModel.isMyRecipeSelectionMode,
                  onToggleSelectionMode: viewModel.toggleMyRecipeSelectionMode,
                  onSelectRecipe: viewModel.selectMyRecipe,
                  selectedIds: viewModel.selectedMyRecipeIds,
                  onHeaderTap: () => _toggleSection('my'),
                  type: 'my',
                ),
                const SizedBox(height: 16),

                // --- 3. 즐겨찾기 섹션 ---
                _buildCollapsibleSection(
                  context: context,
                  viewModel: viewModel,
                  title: '즐겨찾기',
                  recipes: viewModel.favoriteRecipes,
                  isExpanded: _expandedSection == 'favorite',
                  isSelectionMode: viewModel.isFavoriteSelectionMode,
                  onToggleSelectionMode: viewModel.toggleFavoriteSelectionMode,
                  onSelectRecipe: viewModel.selectFavoriteRecipe,
                  selectedIds: viewModel.selectedFavoriteRecipeIds,
                  onHeaderTap: () => _toggleSection('favorite'),
                  type: 'favorite',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAiSection(BuildContext context, RecipeViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI 추천 레시피', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: viewModel.toggleAiSelectionMode,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                  child: Icon(viewModel.isAiSelectionMode ? Icons.close : Icons.add, size: 20),
                ),
              )
            ],
          ),
          const Divider(),
          SizedBox(
            height: 250, // AI 추천 목록은 항상 열려있으므로 충분한 높이를 줌
            child: (viewModel.isLoading && viewModel.filteredAiRecipes.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : (viewModel.filteredAiRecipes.isEmpty)
                ? const Center(child: Text("추천 레시피가 없습니다.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: viewModel.filteredAiRecipes.length,
              itemBuilder: (context, index) {
                final recipe = viewModel.filteredAiRecipes[index];
                return _RecipeListItem(
                  recipe: recipe,
                  isSelectionMode: viewModel.isAiSelectionMode,
                  isSelected: viewModel.selectedAiRecipeIds.contains(recipe.id),
                  onTap: () => viewModel.isAiSelectionMode ? viewModel.selectAiRecipe(recipe.id) : _navigateToDetail(context, viewModel, recipe),
                );
              },
            ),
          ),
          if (viewModel.isAiSelectionMode)
            _buildActionButtons(context, viewModel, 'ai'),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required BuildContext context, required RecipeViewModel viewModel,
    required String title, required List<Recipe> recipes,
    required bool isExpanded, required bool isSelectionMode,
    required VoidCallback onToggleSelectionMode, required VoidCallback onHeaderTap,
    required Function(int) onSelectRecipe, required Set<int> selectedIds,
    required String type,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8)],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onHeaderTap,
            title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            trailing: isExpanded
                ? (type == 'my'
                ? InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRecipeScreen())), child: const Icon(Icons.add))
                : null) // 즐겨찾기는 추가 버튼 없음
                : null,
          ),
          if (isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            SizedBox(
              height: 200,
              child: (viewModel.isLoading && recipes.isEmpty)
                  ? const Center(child: CircularProgressIndicator())
                  : (recipes.isEmpty)
                  ? const Center(child: Text("레시피가 없습니다.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return _RecipeListItem(
                    recipe: recipe, isSelectionMode: isSelectionMode,
                    isSelected: selectedIds.contains(recipe.id),
                    onTap: () => isSelectionMode ? onSelectRecipe(recipe.id) : _navigateToDetail(context, viewModel, recipe),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: _buildActionButtons(context, viewModel, type)),
                  if (type == 'my' || type == 'favorite')
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onToggleSelectionMode,
                    ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, RecipeViewModel viewModel, String type) {
    if (type == 'ai') {
      return Row(
        children: [
          Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.favorite_border), onPressed: viewModel.selectedAiRecipeIds.isNotEmpty ? viewModel.addFavorites : null, label: const Text('즐겨찾기 추가'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.visibility_off_outlined), label: const Text('추천 안함'), onPressed: viewModel.selectedAiRecipeIds.isNotEmpty ? viewModel.blockRecipes : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey))),
        ],
      );
    } else if (type == 'my') {
      if (viewModel.isMyRecipeSelectionMode) {
        return ElevatedButton.icon(icon: const Icon(Icons.delete_outline), label: const Text('삭제'), onPressed: viewModel.selectedMyRecipeIds.isNotEmpty ? viewModel.deleteMyRecipes : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.red));
      } else { return const SizedBox.shrink(); }
    } else { // favorite
      if (viewModel.isFavoriteSelectionMode) {
        return ElevatedButton.icon(icon: const Icon(Icons.favorite_border), label: const Text('즐겨찾기 삭제'), onPressed: viewModel.selectedFavoriteRecipeIds.isNotEmpty ? viewModel.deleteFavorites : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.red));
      } else { return const SizedBox.shrink(); }
    }
  }

  void _navigateToDetail(BuildContext context, RecipeViewModel viewModel, Recipe recipe) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: RecipeDetailScreen(recipe: recipe, userIngredients: viewModel.userIngredients),
      ),
    ));
  }
}

class _RecipeListItem extends StatelessWidget {
  final Recipe recipe;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecipeListItem({required this.recipe, required this.isSelectionMode, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
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
                  Text(recipe.description.isNotEmpty ? recipe.description : '필요 재료: ${recipe.ingredients.join(', ')}', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
