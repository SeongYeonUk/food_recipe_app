// lib/screens/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/statistics_viewmodel.dart';
import '../models/statistics_model.dart';
import '../models/recipe_model.dart';
import './recipe_detail_screen.dart';
import '../viewmodels/recipe_viewmodel.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("통계 및 장보기")),
      body: Consumer<StatisticsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.popularIngredients.isEmpty && viewModel.popularRecipes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null) {
            return Center(child: Text(viewModel.errorMessage!));
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.fetchAllStatistics(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSection(
                  context: context,
                  title: '자주 사용하는 식재료',
                  borderColor: Colors.blue.shade300,
                  isPeriodSelectorVisible: viewModel.isIngredientPeriodSelectorVisible,
                  onToggleSelector: viewModel.toggleIngredientPeriodSelector,
                  onPeriodSelected: (period) {
                    viewModel.fetchPopularIngredients(period: period);
                    viewModel.toggleIngredientPeriodSelector();
                  },
                  child: _buildIngredientRanking(context, viewModel.popularIngredients),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context: context,
                  title: '레시피 순위',
                  borderColor: Colors.purple.shade200,
                  isPeriodSelectorVisible: viewModel.isRecipePeriodSelectorVisible,
                  onToggleSelector: viewModel.toggleRecipePeriodSelector,
                  onPeriodSelected: (period) {
                    viewModel.fetchPopularRecipes(period: period);
                    viewModel.toggleRecipePeriodSelector();
                  },
                  child: _buildRecipeRanking(context, viewModel.popularRecipes),
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
    required String title,
    required Color borderColor,
    required bool isPeriodSelectorVisible,
    required VoidCallback onToggleSelector,
    required Function(Period) onPeriodSelected,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // [솔루션] Expanded 위젯으로 제목을 감싸서, 남는 공간을 모두 차지하도록 합니다.
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              // 이렇게 하면 버튼들은 항상 오른쪽에 고정됩니다.
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isPeriodSelectorVisible
                    ? _buildPeriodButtons(onPeriodSelected)
                    : const SizedBox(width: 0),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onToggleSelector,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPeriodSelectorVisible ? Icons.close : Icons.add,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPeriodButtons(Function(Period) onPeriodSelected) {
    return Row(
      children: [
        _buildPeriodButton(text: '주간', period: Period.weekly, onSelected: onPeriodSelected),
        const SizedBox(width: 8),
        _buildPeriodButton(text: '월간', period: Period.monthly, onSelected: onPeriodSelected),
      ],
    );
  }

  Widget _buildPeriodButton({
    required String text,
    required Period period,
    required Function(Period) onSelected,
  }) {
    return ElevatedButton(
      onPressed: () => onSelected(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(text),
    );
  }

  Widget _buildIngredientRanking(BuildContext context, List<PopularIngredient> ingredients) {
    if (ingredients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      children: ingredients.asMap().entries.map((entry) {
        int index = entry.key;
        PopularIngredient ingredient = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.purple[100], radius: 14, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(child: Text(ingredient.name, style: const TextStyle(fontSize: 16))),
              const Icon(Icons.favorite, color: Colors.red, size: 18),
              const SizedBox(width: 4),
              Text('${ingredient.count}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.shopping_basket, color: Colors.redAccent, size: 24),
                onPressed: () async {
                  final url = Uri.parse(ingredient.coupangUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecipeRanking(BuildContext context, List<PopularRecipe> recipes) {
    if (recipes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      children: recipes.asMap().entries.map((entry) {
        int index = entry.key;
        PopularRecipe recipe = entry.value;
        return InkWell(
          onTap: () {
            final tempRecipe = Recipe(
              id: recipe.id, name: recipe.name, imageUrl: recipe.thumbnail,
              likes: recipe.likeCount, userReaction: recipe.isLiked ? ReactionState.liked : ReactionState.none,
              isFavorite: recipe.isLiked, ingredients: [], instructions: [],
              cookingTime: '', authorNickname: '', isCustom: false,
            );
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: Provider.of<RecipeViewModel>(context, listen: false),
                child: RecipeDetailScreen(recipe: tempRecipe, userIngredients: const []),
              ),
            ));
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.purple[100], radius: 14, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.thumb_up, color: Colors.blue, size: 18),
                const SizedBox(width: 4),
                Text('${recipe.likeCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
