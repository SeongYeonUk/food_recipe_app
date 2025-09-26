// lib/screens/community/post_list_screen.dart

import 'package:flutter/material.dart';
import 'community_widgets.dart';
import '../../models/statistics_model.dart';
import '../../models/review_model.dart';

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
            return ShowcaseGridItem(post: posts[index] as PopularRecipe);
          }
        },
      ),
    );
  }
}
