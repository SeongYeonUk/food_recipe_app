import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/review_model.dart';
import '../../viewmodels/review_viewmodel.dart';
import '../../viewmodels/recipe_viewmodel.dart';
import '../recipe_detail_screen.dart';
import 'package:collection/collection.dart';

class ReviewDetailScreen extends StatelessWidget {
  final Review review;
  const ReviewDetailScreen({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewViewModel = Provider.of<ReviewViewModel>(context);
    final recipeViewModel = Provider.of<RecipeViewModel>(
      context,
      listen: false,
    );

    final targetRecipe = recipeViewModel.allRecipes.firstWhereOrNull(
      (recipe) => recipe.name == review.recipeName,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('레시피 후기')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================================================
                  // ▼▼▼ 바로 이 부분이 수정되었습니다! ▼▼▼
                  // [핵심 수정] '레시피 보러가기' 카드를 후기 제목 위로 이동시켰습니다.
                  if (targetRecipe != null)
                    Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(
                        bottom: 24.0,
                      ), // 제목과의 간격을 위해 아래쪽에 여백 추가
                      child: ListTile(
                        leading: const Icon(
                          Icons.menu_book,
                          color: Colors.green,
                        ),
                        title: Text("'${review.recipeName}' 레시피 보러가기"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: recipeViewModel,
                                child: RecipeDetailScreen(
                                  recipe: targetRecipe,
                                  userIngredients: recipeViewModel
                                      .userIngredients
                                      .map((ing) => ing.name)
                                      .toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // --- 후기 제목 ---
                  Text(
                    review.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // ▲▲▲ 여기까지 수정되었습니다! ▲▲▲
                  // =============================================================
                  const SizedBox(height: 8),

                  // --- 후기 정보 (작성자, 조회수 등) ---
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '익명',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.visibility,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${review.views}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // --- 후기 사진 (있을 경우) ---
                  if (review.imageUrl != null &&
                      review.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(review.imageUrl!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- 후기 내용 ---
                  Text(
                    review.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // --- 하단 좋아요 버튼 ---
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: ElevatedButton.icon(
              icon: Icon(
                review.isLiked ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              label: Text(
                '좋아요 ${review.likes}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              onPressed: () {
                reviewViewModel.toggleLike(review);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: review.isLiked
                    ? Colors.redAccent
                    : Colors.grey,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
