// lib/screens/community/recipe_review_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recipe_viewmodel.dart';
import 'community_widgets.dart';

class RecipeReviewScreen extends StatelessWidget {
  const RecipeReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피 후기'),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
        ],
      ),
      body: Consumer<RecipeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bestReviewPosts = viewModel.allAiRecipes;
          final todayReviewPosts = viewModel.customRecipes;

          return SingleChildScrollView(
            child: Column(
              children: [
                TopMenuBar(currentIndex: 1),
                const SizedBox(height: 16),
                PostSection(
                  title: '베스트 레시피 후기',
                  titleColor: Colors.orange.shade100,
                  posts: bestReviewPosts,
                  isReview: true,
                ),
                const SizedBox(height: 24),
                PostSection(
                  title: '오늘 올라온 레시피 후기',
                  titleColor: Colors.orange.shade100,
                  posts: todayReviewPosts,
                  isReview: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

