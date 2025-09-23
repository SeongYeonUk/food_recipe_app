// lib/screens/community/community_widgets.dart

import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../viewmodels/recipe_viewmodel.dart';
import 'package:provider/provider.dart';
import 'recipe_showcase_screen.dart';
import 'recipe_review_screen.dart';
import '../recipe_detail_screen.dart';

class TopMenuBar extends StatelessWidget {
  final int currentIndex;
  const TopMenuBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'label': '레시피 자랑', 'color': Colors.lightGreenAccent.shade400, 'screen': const RecipeShowcaseScreen()},
      {'label': '레시피 후기', 'color': Colors.lightGreenAccent.shade400, 'screen': const RecipeReviewScreen()},
      {'label': '오늘의 레시피', 'color': Colors.green.shade700},
      {'label': '전문가 레시피', 'color': Colors.green.shade700},
      {'label': '장보기 추천', 'color': Colors.blue.shade300},
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final bool isSelected = index == currentIndex;
          return GestureDetector(
            onTap: () {
              if (item['screen'] != null && !isSelected) {
                Navigator.pushReplacement(context, PageRouteBuilder(
                  pageBuilder: (_, __, ___) => item['screen'],
                  transitionDuration: Duration.zero,
                ));
              }
            },
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                // [솔루션] mainAxisAlignment를 start로 변경하여 위쪽부터 그리도록 합니다.
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 4), // 위쪽 여백 추가
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: item['color'],
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PostSection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<Recipe> posts;
  final bool isReview;
  const PostSection({super.key, required this.title, required this.titleColor, required this.posts, this.isReview = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: titleColor,
                  borderRadius: const BorderRadius.all(Radius.elliptical(16, 16)),
                ),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(onPressed: () {}, child: const Text('더보기')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: posts.length > 6 ? 6 : posts.length,
          itemBuilder: (context, index) {
            return isReview
                ? ReviewGridItem(post: posts[index])
                : PostGridItem(post: posts[index]);
          },
        ),
      ],
    );
  }
}

class PostGridItem extends StatelessWidget {
  final Recipe post;
  const PostGridItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final recipeViewModel = Provider.of<RecipeViewModel>(context, listen: false);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: recipeViewModel,
            child: RecipeDetailScreen(
              recipe: post,
              userIngredients: recipeViewModel.userIngredients,
            ),
          ),
        ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                image: post.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(post.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: post.imageUrl.isEmpty ? const Icon(Icons.photo, color: Colors.grey, size: 40) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(post.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 2), Text('${post.likes}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}

class ReviewGridItem extends StatelessWidget {
  final Recipe post;
  const ReviewGridItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final recipeViewModel = Provider.of<RecipeViewModel>(context, listen: false);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: recipeViewModel,
            child: RecipeDetailScreen(
              recipe: post,
              userIngredients: recipeViewModel.userIngredients,
            ),
          ),
        ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                image: post.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(post.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: post.imageUrl.isEmpty ? const Icon(Icons.photo, color: Colors.grey, size: 40) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(post.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(post.authorNickname, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
