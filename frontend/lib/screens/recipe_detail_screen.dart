import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';
import 'community/review_creation_screen.dart';

/// Recipe detail screen with nutrition/price toggle under the title.
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe; // initial recipe (fallback)
  final List<String> userIngredients;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.userIngredients,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _showNutrition = false;
  bool _showPrice = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeViewModel>(
      builder: (context, viewModel, child) {
        final Recipe? liveRecipe = [
          ...viewModel.allAiRecipes,
          ...viewModel.myRecipes,
        ].firstWhereOrNull((r) => r.id == widget.recipe.id);
        final Recipe currentRecipe = liveRecipe ?? widget.recipe;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentRecipe.name),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentRecipe.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            currentRecipe.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey.shade200,
                              height: 180,
                              child: const Center(
                                  child: Icon(Icons.no_photography)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        currentRecipe.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (currentRecipe.description.isNotEmpty)
                        Text(
                          currentRecipe.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TogglePill(
                            label: '영양 보기',
                            icon: Icons.health_and_safety_outlined,
                            isOn: _showNutrition,
                            onTap: () => setState(() {
                              _showNutrition = !_showNutrition;
                            }),
                          ),
                          _TogglePill(
                            label: '가격 보기',
                            icon: Icons.sell_outlined,
                            isOn: _showPrice,
                            onTap: () => setState(() {
                              _showPrice = !_showPrice;
                            }),
                          ),
                        ],
                      ),
                      if (_showNutrition)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _NutritionBlock(recipe: currentRecipe),
                        ),
                      if (_showPrice)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _PriceBlock(recipe: currentRecipe),
                        ),
                      const SizedBox(height: 16),
                      _InfoCard(recipe: currentRecipe),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Ingredients'),
                      _IngredientsList(
                        ingredients: currentRecipe.ingredients,
                        userIngredients: widget.userIngredients,
                      ),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Instructions'),
                      _InstructionsList(
                        instructions: currentRecipe.instructions,
                      ),
                    ],
                  ),
                ),
              ),
              _BuildReactionButtons(
                recipeId: currentRecipe.id,
                initialRecipe: widget.recipe,
              ),
            ],
          ),
        );
      },
    );
  }
} // RecipeDetailScreen 클래스 종료

// =================================================================================

// 💡 [오류 1 해결] - 모든 보조 위젯들은 이제 클래스 외부(파일 최하단)에 정의됩니다.

// 파일 상단에 http 패키지를 import 하세요.

// =================================================================================
// ▼▼▼ 이 클래스 전체를 복사해서 기존 코드를 덮어쓰세요 ▼▼▼
class _CustomSliverAppBar extends StatelessWidget {
  final Recipe recipe;
  const _CustomSliverAppBar({required this.recipe});

  // 디버깅을 위한 함수
  void _checkImageStatus(String url) async {
    print('>>> [디버그] 이미지 URL 테스트 시작: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('>>> [디버그] 서버 응답 코드: ${response.statusCode}');
      print('>>> [디버그] 응답 내용 길이: ${response.contentLength} bytes');
    } catch (e) {
      print('>>> [디버그] HTTP 요청 중 에러 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      // background에 _buildBackgroundImage(context)를 호출하도록 변경
      flexibleSpace: FlexibleSpaceBar(
        background: _buildBackgroundImage(context),
      ),
    );
  }

  // 이 메서드의 내용이 수정되었습니다!
  Widget _buildBackgroundImage(BuildContext context) {
    String imageUrl = recipe.imageUrl;

    // 1. 서버 경로 처리 로직 추가
    if (imageUrl.startsWith('/')) {
      const serverIp = 'http://10.210.59.37:8080';
      imageUrl = serverIp + imageUrl;
    }

    // 2. 디버깅 함수 호출
    _checkImageStatus(imageUrl);

    // 3. Image.network로 모든 이미지 처리 통일
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('>>> [디버그] Image.network 위젯 에러: $error');
        return Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.no_photography)),
        );
      },
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, color: Colors.deepOrangeAccent),
            const SizedBox(width: 8),
            Text(
              recipe.cookingTime,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionBlock extends StatelessWidget {
  final Recipe recipe;
  const _NutritionBlock({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final hasData = recipe.totalKcal != null ||
        recipe.totalCarbsG != null ||
        recipe.totalProteinG != null ||
        recipe.totalFatG != null ||
        recipe.totalSodiumMg != null ||
        recipe.estimatedMinPriceKrw != null ||
        recipe.estimatedMaxPriceKrw != null;

    if (!hasData) {
      return const Text(
        'No nutrition/price info.',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }

    String numStr(double? v, {int digits = 1, String unit = ''}) {
      if (v == null) return '-';
      return '${v.toStringAsFixed(digits)}$unit';
    }

    String priceStr(double? min, double? max) {
      if (min == null && max == null) return '-';
      if (min != null && max != null) {
        return '${min.toStringAsFixed(0)} ~ ${max.toStringAsFixed(0)}원';
      }
      return '${(min ?? max)?.toStringAsFixed(0)}원';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _chip('칼로리', numStr(recipe.totalKcal, unit: ' kcal')),
              _chip('탄수화물', numStr(recipe.totalCarbsG, unit: ' g')),
              _chip('단백질', numStr(recipe.totalProteinG, unit: ' g')),
              _chip('지방', numStr(recipe.totalFatG, unit: ' g')),
              _chip('나트륨', numStr(recipe.totalSodiumMg, unit: ' mg')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '예상 가격: ${priceStr(recipe.estimatedMinPriceKrw, recipe.estimatedMaxPriceKrw)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildReactionButtons extends StatelessWidget {
  final int recipeId;
  final Recipe initialRecipe;

  const _BuildReactionButtons({
    required this.recipeId,
    required this.initialRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeViewModel>(
      builder: (context, viewModel, child) {
        final Recipe? liveRecipe = [
          ...viewModel.allAiRecipes,
          ...viewModel.myRecipes,
        ].firstWhereOrNull((r) => r.id == recipeId);
        final Recipe currentRecipe = liveRecipe ?? initialRecipe;
        final likeCount = currentRecipe.likes < 0 ? 0 : currentRecipe.likes;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    icon: Icon(
                      currentRecipe.userReaction == ReactionState.liked
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      color: currentRecipe.userReaction == ReactionState.liked
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    label: Text('좋아요 $likeCount'),
                    onPressed: () => viewModel.updateReaction(
                      currentRecipe.id,
                      ReactionState.liked,
                      context,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      currentRecipe.userReaction == ReactionState.disliked
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      color: currentRecipe.userReaction ==
                              ReactionState.disliked
                          ? Colors.red
                          : Colors.grey,
                    ),
                    label: const Text('싫어요'),
                    onPressed: () => viewModel.updateReaction(
                      currentRecipe.id,
                      ReactionState.disliked,
                      context,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('후기 작성'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewCreationScreen(recipe: currentRecipe),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// --------------- 가격 블록 ----------------
class _PriceBlock extends StatelessWidget {
  final Recipe recipe;
  const _PriceBlock({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final hasPrice = recipe.estimatedMinPriceKrw != null ||
        recipe.estimatedMaxPriceKrw != null;
    if (!hasPrice) {
      return const Text(
        '가격 정보가 없습니다.',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }

    String priceStr(double? min, double? max) {
      if (min == null && max == null) return '-';
      if (min != null && max != null) {
        return '${min.toStringAsFixed(0)} ~ ${max.toStringAsFixed(0)}원';
      }
      return '${(min ?? max)?.toStringAsFixed(0)}원';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '예상 가격: ${priceStr(recipe.estimatedMinPriceKrw, recipe.estimatedMaxPriceKrw)}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// --------------- 냉장고 카드 스타일 토글 pill ----------------
class _TogglePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isOn;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.icon,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isOn ? Colors.white : Colors.brown.shade400,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isOn ? Colors.white : Colors.brown.shade400,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.brown.shade400,
        backgroundColor: isOn ? Colors.brown.shade300 : Colors.white,
        side: BorderSide(color: Colors.brown.shade300, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final List<String> ingredients;
  final List<String> userIngredients;
  const _IngredientsList({
    required this.ingredients,
    required this.userIngredients,
  });

  @override
  Widget build(BuildContext context) {
    final ingredientsDisplay = ingredients
        .map((ing) => ing.trim())
        .where((ing) => ing.isNotEmpty)
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ingredientsDisplay.length,
      itemBuilder: (context, index) {
        final ingredient = ingredientsDisplay[index];
        final isInUserIngredients = userIngredients.any(
          (userIng) =>
              userIng.trim().toLowerCase() == ingredient.trim().toLowerCase(),
        );

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isInUserIngredients ? Icons.check_circle : Icons.remove_circle,
            color: isInUserIngredients ? Colors.green : Colors.grey,
          ),
          title: Text(
            ingredient,
            style: TextStyle(
              decoration: isInUserIngredients
                  ? TextDecoration.none
                  : TextDecoration.lineThrough,
              color: isInUserIngredients ? Colors.black : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}

class _InstructionsList extends StatelessWidget {
  final List<String> instructions;
  const _InstructionsList({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final steps = instructions
        .asMap()
        .entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.deepOrange.shade100,
            child: Text(
              '${step.key + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
          title: Text(
            step.value.trim(),
            style: const TextStyle(fontSize: 15),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
