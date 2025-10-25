import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';
import '../viewmodels/statistics_viewmodel.dart'; // ⭐ StatisticsViewModel 추가
import 'community/review_creation_screen.dart';

// RecipeDetailScreen 클래스 시작
class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe; // 최초 API 호출로 받은 레시피 데이터 (Fallback용)
  final List<String> userIngredients;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.userIngredients,
  });

  // 💡 [오류 1 해결] - _buildBorderBox 메서드는 클래스 내부에 정의되어야 합니다.
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

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeViewModel>(
      builder: (context, viewModel, child) {
        // ⭐ 1. 뷰모델의 내부 목록에서 최신 상태의 레시피 객체를 찾습니다.
        final Recipe? liveRecipe = [
          ...viewModel.allAiRecipes,
          ...viewModel.myRecipes,
        ].firstWhereOrNull((r) => r.id == recipe.id);

        // 2. liveRecipe가 있으면 최신 상태를 사용하고, 없으면 최초 객체(recipe)를 대안으로 사용합니다.
        final Recipe currentRecipe = liveRecipe ?? recipe;

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
                                  Text(
                                    currentRecipe.name,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentRecipe.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _InfoCard(recipe: currentRecipe),
                                  const SizedBox(height: 24),
                                  const _SectionHeader(title: '재료'),
                                  _IngredientsList(
                                    ingredients: currentRecipe.ingredients,
                                    userIngredients: userIngredients,
                                  ),
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
                                  _InstructionsList(
                                    instructions: currentRecipe.instructions,
                                  ),
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
              // ⭐⭐⭐ 좋아요 버튼 위젯 호출 (실시간 갱신 보장) ⭐⭐⭐
              _BuildReactionButtons(
                recipeId: currentRecipe.id,
                initialRecipe: recipe, // 최초 객체를 대안으로 전달
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
      const serverIp = 'http://10.210.97.105:8080';
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
// ▲▲▲ 여기까지 ▲▲▲
// =================================================================================

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
          // 💡 [오류 2 해결] - 인자 2개만 전달
          children: [_InfoItem(icon: Icons.timer, text: recipe.cookingTime)],
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

// ---------------------------------------------------------------------------------
// ********* 좋아요 카운트와 버튼을 실시간으로 갱신하는 위젯 **********
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
        // 1. 뷰모델의 최신 목록에서 현재 레시피를 ID로 다시 찾습니다.
        final Recipe? liveRecipe = [
          ...viewModel.allAiRecipes,
          ...viewModel.myRecipes,
        ].firstWhereOrNull((r) => r.id == recipeId);

        // 2. 최신 객체를 최우선으로 사용하고, 없으면 초기 객체를 사용합니다. (버튼 사라짐 방지)
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
              // 왼쪽: 좋아요, 싫어요 버튼 그룹
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
                    label: Text(
                      "좋아요 $likeCount", // ✅ 갱신된 카운트 사용
                      style: TextStyle(
                        color: currentRecipe.userReaction == ReactionState.liked
                            ? Colors.blue
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => viewModel.updateReaction(
                      currentRecipe.id,
                      ReactionState.liked,
                      context, // 💡 context 전달 (StatisticsViewModel 동기화용)
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(
                      currentRecipe.userReaction == ReactionState.disliked
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      color:
                          currentRecipe.userReaction == ReactionState.disliked
                          ? Colors.red
                          : Colors.grey,
                    ),
                    label: const Text(
                      "싫어요",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => viewModel.updateReaction(
                      currentRecipe.id,
                      ReactionState.disliked,
                      context, // 💡 context 전달 (StatisticsViewModel 동기화용)
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              // 오른쪽: 후기 작성 버튼
              TextButton.icon(
                icon: const Icon(
                  Icons.rate_review_outlined,
                  color: Colors.grey,
                ),
                label: const Text(
                  "후기 작성",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewCreationScreen(
                        recipe: currentRecipe,
                      ), // 갱신된 객체 전달
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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

// ---------------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
    return Column(
      children: ingredients.map((recipeIngredient) {
        final coreIngredient = recipeIngredient.split(' ')[0];
        final bool hasIngredient = userIngredients.any(
          (userIng) => coreIngredient.contains(userIng),
        );
        return ListTile(
          leading: Icon(
            hasIngredient ? Icons.check_circle : Icons.remove_circle_outline,
            color: hasIngredient ? Colors.green : Colors.grey,
          ),
          title: Text(
            recipeIngredient,
            style: TextStyle(
              color: hasIngredient ? Colors.black : Colors.grey,
              decoration: hasIngredient
                  ? TextDecoration.none
                  : TextDecoration.lineThrough,
            ),
          ),
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
            title: Text(instructions[i], style: const TextStyle(height: 1.4)),
          ),
      ],
    );
  }
}
