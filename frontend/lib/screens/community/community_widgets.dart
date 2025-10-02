import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'community_data.dart';
import '../../models/recipe_model.dart';
import '../../models/statistics_model.dart';
import '../../models/review_model.dart';
import '../../viewmodels/recipe_viewmodel.dart';
import '../../viewmodels/statistics_viewmodel.dart';
import '../recipe_detail_screen.dart';
import 'review_detail_screen.dart';
import 'post_list_screen.dart';

class TopMenuBar extends StatelessWidget {
  final int currentIndex;
  final ItemScrollController _scrollController = ItemScrollController();
  TopMenuBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(index: currentIndex);
    });
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      ),
      child: ScrollablePositionedList.builder(
        itemScrollController: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: communityCategories.length,
        itemBuilder: (context, index) {
          final item = communityCategories[index];
          final bool isSelected = (index == currentIndex);
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
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
                    style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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

class ShowcasePostSection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<PopularRecipe> posts;
  const ShowcasePostSection({super.key, required this.title, required this.titleColor, required this.posts});

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
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.elliptical(16, 16)),
                  border: Border.all(color: titleColor, width: 1.5),
                ),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PostListScreen(title: title, posts: posts),
                  ));
                },
                child: const Text('더보기'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.7,
          ),
          itemCount: posts.length > 6 ? 6 : posts.length,
          itemBuilder: (context, index) => ShowcaseGridItem(post: posts[index]),
        ),
      ],
    );
  }
}

class ShowcaseGridItem extends StatelessWidget {
  final PopularRecipe post;
  const ShowcaseGridItem({super.key, required this.post});
  @override
  Widget build(BuildContext context) {
    final recipeViewModel = Provider.of<RecipeViewModel>(context, listen: false);
    final statisticsViewModel = Provider.of<StatisticsViewModel>(context, listen: false);
    return GestureDetector(
      onTap: () {
        statisticsViewModel.incrementRecipeView(post);
        // [수정 안함] 이 부분은 사용자님의 원래 코드를 그대로 유지하여 오류를 방지했습니다.
        final tempRecipe = Recipe(
          id: post.id, name: post.name, description: '', imageUrl: post.thumbnail,
          likes: post.likeCount.toInt(), isFavorite: post.isLiked,
          ingredients: [], instructions: [], cookingTime: '', authorNickname: 'AI', isCustom: false,
        );
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: recipeViewModel,
            child: RecipeDetailScreen(recipe: tempRecipe, userIngredients: recipeViewModel.userIngredients),
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
                color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8),
                image: post.thumbnail.isNotEmpty ? DecorationImage(image: NetworkImage(post.thumbnail), fit: BoxFit.cover) : null,
              ),
              child: post.thumbnail.isEmpty ? const Icon(Icons.photo, color: Colors.grey, size: 40) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(post.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 2), Text('${post.likeCount}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 8),
              const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 2), Text('${post.viewCount}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}

class ReviewPostSection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<Review> posts;
  const ReviewPostSection({super.key, required this.title, required this.titleColor, required this.posts});

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
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.elliptical(16, 16)),
                  border: Border.all(color: titleColor, width: 1.5),
                ),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PostListScreen(title: title, posts: posts, isReview: true),
                  ));
                },
                child: const Text('더보기'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.7,
          ),
          itemCount: posts.length > 6 ? 6 : posts.length,
          itemBuilder: (context, index) => ReviewGridItem(post: posts[index]),
        ),
      ],
    );
  }
}

// ==================================================================
// ▼▼▼ 바로 이 위젯이 수정되었습니다! ▼▼▼
// [핵심 수정] ReviewGridItem 위젯의 이미지 표시 부분을 변경했습니다.
class ReviewGridItem extends StatelessWidget {
  final Review post;
  const ReviewGridItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // [수정 안함] 사용자님의 원래 코드를 그대로 유지하여 오류를 방지했습니다.
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: post)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  ? Image.file(
                File(post.imageUrl!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              )
              // 이미지가 없을 때 '사진 없음' 아이콘과 텍스트를 함께 표시합니다.
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo, color: Colors.grey, size: 40),
                    SizedBox(height: 4),
                    Text('사진 없음', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${post.recipeName} 후기', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
// ▲▲▲ 여기까지 수정되었습니다! ▲▲▲
// ==================================================================

