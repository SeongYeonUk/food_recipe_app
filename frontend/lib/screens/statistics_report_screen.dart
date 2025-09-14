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
          if (viewModel.isLoading && viewModel.popularIngredients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSection(
                context: context,
                title: '자주 사용하는 식재료',
                isPeriodSelectorVisible: viewModel.isIngredientPeriodSelectorVisible,
                onToggleSelector: viewModel.toggleIngredientPeriodSelector,
                onPeriodSelected: (period) {
                  viewModel.fetchStatisticsByPeriod(period: period);
                  viewModel.toggleIngredientPeriodSelector();
                },
                child: _buildIngredientRanking(context, viewModel.popularIngredients),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context: context,
                title: '레시피 순위',
                isPeriodSelectorVisible: viewModel.isRecipePeriodSelectorVisible,
                onToggleSelector: viewModel.toggleRecipePeriodSelector,
                onPeriodSelected: (period) {
                  viewModel.toggleRecipePeriodSelector();
                },
                child: _buildRecipeRanking(context, viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required bool isPeriodSelectorVisible,
    required VoidCallback onToggleSelector,
    required Function(Period) onPeriodSelected,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: title == '레시피 순위' ? const Color(0xFFE040FB) : const Color(0xFF536DFE), // 보라색 / 파란색 테두리
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: Row(
                    children: [
                      if (isPeriodSelectorVisible)
                        _buildPeriodButtons(onPeriodSelected),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.grey.shade200,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onToggleSelector,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },
                              child: Icon(
                                isPeriodSelectorVisible ? Icons.close : Icons.add,
                                key: ValueKey<bool>(isPeriodSelectorVisible),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: child,
          ),
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
        backgroundColor: const Color(0xFF00BFA5), // 민트색 계열
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
      ),
      child: Text(text),
    );
  }

  Widget _buildIngredientRanking(BuildContext context, List<PopularIngredient> ingredients) {
    return Column(
      children: ingredients.asMap().entries.map((entry) {
        int index = entry.key;
        PopularIngredient ingredient = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.purple[100], radius: 12, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white))),
              const SizedBox(width: 16),
              Expanded(child: Text(ingredient.name, style: const TextStyle(fontSize: 16))),
              const Icon(Icons.favorite, color: Colors.red, size: 20),
              const SizedBox(width: 4),
              Text('${ingredient.count}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.shopping_basket, color: Colors.redAccent, size: 24),
                onPressed: () async {
                  final url = Uri.parse(ingredient.coupangUrl);
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    print('URL 실행 중 오류 발생: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('링크를 여는 중 오류가 발생했습니다.')));
                    }
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecipeRanking(BuildContext context, StatisticsViewModel viewModel) {
    final recipeViewModel = Provider.of<RecipeViewModel>(context, listen: false);
    final userIngredients = recipeViewModel.userIngredients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...viewModel.popularRecipes.asMap().entries.map((entry) {
          int index = entry.key;
          Recipe recipe = entry.value;
          bool isSelected = viewModel.selectedRecipeIds.contains(recipe.id);
          return InkWell(
            onTap: () {
              if (!viewModel.isRecipeSelectionMode) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: recipeViewModel,
                      child: RecipeDetailScreen(recipe: recipe, userIngredients: userIngredients),
                    ),
                  ),
                );
              } else {
                viewModel.selectRecipe(recipe.id);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (viewModel.isRecipeSelectionMode)
                    Checkbox(value: isSelected, onChanged: (_) => viewModel.selectRecipe(recipe.id)),
                  if (!viewModel.isRecipeSelectionMode)
                    CircleAvatar(backgroundColor: Colors.purple[100], radius: 12, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('필요 재료: ${recipe.ingredients.join(', ')}', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.thumb_up, color: Colors.blue, size: 20),
                  const SizedBox(width: 4),
                  Text('${recipe.likes}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }).toList(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SizeTransition(sizeFactor: animation, child: child);
          },
          child: (viewModel.isRecipeSelectionMode && viewModel.selectedRecipeIds.isNotEmpty)
              ? Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                await viewModel.addFavorites();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('선택한 레시피가 \'나만의 레시피\'에 추가되었습니다.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFE082), // 연한 노란색
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: const Text('즐겨찾기 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}


