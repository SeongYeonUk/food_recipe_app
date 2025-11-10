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
      body: const RecipeReviewSection(),
    );
  }
}

// Section-only widget (no Scaffold/AppBar). Use inside CommunityScreen.
class RecipeReviewSection extends StatelessWidget {
  const RecipeReviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (viewModel.bestReviews.isNotEmpty) ...[
                ReviewPostSection(
                  title: '베스트 후기',
                  titleColor: Colors.orange,
                  posts: viewModel.bestReviews,
                ),
                const SizedBox(height: 24),
              ],

              if (viewModel.todayReviews.isNotEmpty) ...[
                ReviewPostSection(
                  title: '오늘 후기',
                  titleColor: Colors.orange,
                  posts: viewModel.todayReviews,
                ),
                const SizedBox(height: 24),
              ],

              if (viewModel.bestReviews.isEmpty && viewModel.todayReviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Text('아직 등록된 후기가 없습니다.'),
                ),
            ],
          ),
        );
      },
    );
  }
}

