// lib/screens/community/recipe_review_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/review_viewmodel.dart';
import 'community_widgets.dart';

class RecipeReviewScreen extends StatelessWidget {
  const RecipeReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('레시피 후기')),
      body: Consumer<ReviewViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                TopMenuBar(currentIndex: 5),
                const SizedBox(height: 16),
                ReviewPostSection(
                  title: '베스트 레시피 후기',
                  titleColor: Colors.orange.shade100,
                  posts: viewModel.bestReviews,
                ),
                const SizedBox(height: 24),
                ReviewPostSection(
                  title: '오늘 올라온 레시피 후기',
                  titleColor: Colors.orange.shade100,
                  posts: viewModel.todayReviews,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
