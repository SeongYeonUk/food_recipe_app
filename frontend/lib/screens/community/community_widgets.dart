import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'community_data.dart';
import '../../models/recipe_model.dart';
import '../../models/review_model.dart';
import 'post_list_screen.dart';
import '../recipe_detail_screen.dart';
import 'review_detail_screen.dart';

class TopMenuBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onSelect;
  TopMenuBar({super.key, required this.currentIndex, this.onSelect});

  final ItemScrollController _scrollController = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached) {
        _scrollController.jumpTo(index: currentIndex);
      }
    });
    final count = communityCategories.length;
    BoxDecoration deco = BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
    );

    const double barHeight = 96;

    if (count <= 4) {
      // 균등 배치
      return Container(
        height: barHeight,
        decoration: deco,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(count, (index) {
            final item = communityCategories[index];
            final bool isSelected = index == currentIndex;
            return _MenuItem(
              label: item['label'] as String,
              color: item['color'] as Color,
              isSelected: isSelected,
              onTap: () => onSelect?.call(index),
            );
          }),
        ),
      );
    }

    // 5개 이상이면 스크롤
    return Container(
      height: barHeight,
      decoration: deco,
      child: ScrollablePositionedList.builder(
        itemScrollController: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: communityCategories.length,
        itemBuilder: (context, index) {
          final item = communityCategories[index];
          final bool isSelected = index == currentIndex;
          return _MenuItem(
            label: item['label'] as String,
            color: item['color'] as Color,
            isSelected: isSelected,
            onTap: () => onSelect?.call(index),
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _MenuItem({required this.label, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}

class ShowcasePostSection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<Recipe> posts;
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: titleColor, width: 1.5),
                ),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostListScreen(title: title, posts: posts)),
                ),
                child: const Text('자세히'),
              )
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
          itemBuilder: (context, index) => ShowcaseGridItem(post: posts[index]),
        ),
      ],
    );
  }
}

class ShowcaseGridItem extends StatelessWidget {
  final Recipe post;
  const ShowcaseGridItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipe: post,
            userIngredients: const [],
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))
        ]),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Center(child: Icon(Icons.photo, color: Colors.grey, size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.black87),
                            const SizedBox(width: 4),
                            Text('${post.viewCount}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_border_outlined, size: 14, color: Colors.black87),
                            const SizedBox(width: 4),
                            Text('${post.favoriteCount}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.thumb_up_off_alt_outlined, size: 14, color: Colors.black87),
                          const SizedBox(width: 4),
                          Text('${post.likes}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: titleColor, width: 1.5),
                ),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostListScreen(title: title, posts: posts, isReview: true),
                  ),
                ),
                child: const Text('자세히'),
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
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: posts.length > 6 ? 6 : posts.length,
          itemBuilder: (context, index) => ReviewGridItem(post: posts[index]),
        ),
      ],
    );
  }
}

class ReviewGridItem extends StatelessWidget {
  final Review post;
  const ReviewGridItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: post)),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))
        ]),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Center(child: Icon(Icons.photo, color: Colors.grey, size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
