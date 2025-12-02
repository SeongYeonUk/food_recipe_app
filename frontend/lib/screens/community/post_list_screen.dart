// lib/screens/community/post_list_screen.dart

import 'package:flutter/material.dart';
import 'community_widgets.dart';
import '../../models/statistics_model.dart';
import '../../models/review_model.dart';
import '../../models/recipe_model.dart';

class PostListScreen extends StatelessWidget {
  final String title;
  final List<dynamic> posts;
  final bool isReview;

  const PostListScreen({
    super.key,
    required this.title,
    required this.posts,
    this.isReview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          if (isReview) {
            return ReviewGridItem(post: posts[index] as Review);
          } else {
            final item = posts[index];
            if (item is Recipe) {
              return ShowcaseGridItem(post: item);
            }
            return ShowcaseGridItem(
              post: Recipe.basic(
                id: item.id,
                name: item.name,
                likes: item.likeCount,
                favoriteCount: item.favoriteCount ?? 0,
                viewCount: item.viewCount ?? 0,
              ),
            );
          }
        },
      ),
    );
  }
}

