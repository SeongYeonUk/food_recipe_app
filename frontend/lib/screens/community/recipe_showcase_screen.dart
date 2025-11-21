// lib/screens/community/recipe_showcase_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/statistics_viewmodel.dart';
import '../../models/recipe_model.dart';
import 'community_widgets.dart';
import '../recipe_detail_screen.dart';

class RecipeShowcaseScreen extends StatelessWidget {
  const RecipeShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => viewModel.fetchAllStatistics(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                ShowcasePostSection(
                  title: '많이 본 레시피',
                  titleColor: Colors.red,
                  posts: viewModel.mostViewedRecipes
                      .map(
                        (p) => Recipe.basic(
                          id: p.id,
                          name: p.name,
                          likes: p.likeCount,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                ShowcasePostSection(
                  title: '오늘의 자랑 레시피',
                  titleColor: Colors.orange,
                  posts: viewModel.todayShowcaseRecipes
                      .map(
                        (p) => Recipe.basic(
                          id: p.id,
                          name: p.name,
                          likes: p.likeCount,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
