// lib/screens/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/statistics_viewmodel.dart';
import '../models/statistics_model.dart';
import '../models/recipe_model.dart';
import './recipe_detail_screen.dart';
import '../viewmodels/recipe_viewmodel.dart';
import '../viewmodels/refrigerator_viewmodel.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("통계 및 장보기")),
      body: Consumer<StatisticsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading &&
              viewModel.popularIngredients.isEmpty &&
              viewModel.popularRecipes.isEmpty) {
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
                  isPeriodSelectorVisible:
                  viewModel.isIngredientPeriodSelectorVisible,
                  onToggleSelector: viewModel.toggleIngredientPeriodSelector,
                  onPeriodSelected: (period) {
                    viewModel.fetchPopularIngredients(period: period);
                    viewModel.toggleIngredientPeriodSelector();
                  },
                  child: _buildIngredientRanking(
                    context,
                    viewModel.popularIngredients,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context: context,
                  title: '레시피 순위',
                  borderColor: Colors.purple.shade200,
                  isPeriodSelectorVisible:
                  viewModel.isRecipePeriodSelectorVisible,
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // [솔루션] Expanded 위젯으로 제목을 감싸서, 남는 공간을 모두 차지하도록 합니다.
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        _buildPeriodButton(
          text: '주간',
          period: Period.weekly,
          onSelected: onPeriodSelected,
        ),
        const SizedBox(width: 8),
        _buildPeriodButton(
          text: '월간',
          period: Period.monthly,
          onSelected: onPeriodSelected,
        ),
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

  Widget _buildIngredientRanking(
      BuildContext context,
      List<PopularIngredient> ingredients,
      ) {
    if (ingredients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Column(
      children: ingredients.asMap().entries.map((entry) {
        int index = entry.key;
        // [변경점] 모델에 coupangUrl이 없으므로, final PopularIngredient ingredient -> PopularIngredient ingredient로 변경
        PopularIngredient ingredient = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple[100],
                radius: 14,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  ingredient.name,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Icon(Icons.favorite, color: Colors.red, size: 18),
              const SizedBox(width: 4),
              Text(
                '${ingredient.count}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.shopping_basket,
                  color: Colors.redAccent,
                  size: 24,
                ),
                onPressed: () async {
                  // [변경점 1] 모델의 coupangUrl을 사용하는 대신, name을 이용해 URL을 직접 만듭니다.
                  String ingredientName = ingredient.name;

                  // [변경점 2] 한글이나 특수문자를 위해 URL 인코딩을 추가하면 더 안전합니다.
                  String encodedName = Uri.encodeComponent(ingredientName);
                  String urlString =
                      "https://www.coupang.com/np/search?q=$encodedName";

                  final Uri url = Uri.parse(urlString);

                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    // URL 실행에 실패했을 경우를 대비한 로그 (선택 사항)
                    print("Could not launch $url");
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecipeRanking(
      BuildContext context,
      List<PopularRecipe> recipes,
      ) {
    if (recipes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Column(
      children: recipes.asMap().entries.map((entry) {
        int index = entry.key;
        PopularRecipe recipe = entry.value;
        return InkWell(
          onTap: () async {
            // 로딩 중임을 사용자에게 보여줍니다.
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
              const Center(child: CircularProgressIndicator()),
            );

            try {
              // 1. ViewModel을 통해 ID로 레시피 상세 정보를 API로 요청합니다.
              final fullRecipe = await context
                  .read<RecipeViewModel>()
                  .fetchRecipeById(recipe.id);

              final userIngredientNames = context
                  .read<RefrigeratorViewModel>()
                  .userIngredients
                  .map((ing) => ing.name)
                  .toList();

              Navigator.pop(context); // 로딩 다이얼로그 닫기

              // 3. 받아온 전체 정보와 함께 상세 페이지로 이동합니다.
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(
                      recipe: fullRecipe, // ✅ 전체 레시피 정보 전달
                      userIngredients: userIngredientNames, // ✅ 사용자 재료 목록 전달
                    ),
                  ),
                );
              }
            } catch (e) {
              Navigator.pop(context); // 오류 시에도 로딩 다이얼로그 닫기
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("레시피를 불러오는 데 실패했습니다.")));
              }
            }
          },

          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple[100],
                  radius: 14,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.thumb_up, color: Colors.blue, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${recipe.likeCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}