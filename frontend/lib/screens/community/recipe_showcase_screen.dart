// lib/screens/community/recipe_showcase_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recipe_viewmodel.dart';
import 'community_widgets.dart';

class RecipeShowcaseScreen extends StatelessWidget {
  const RecipeShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피 자랑'),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
        ],
      ),
      body: Consumer<RecipeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final mostViewedPosts = [...viewModel.allAiRecipes]..sort((a, b) => b.likes.compareTo(a.likes));
          final todayShowcasePosts = viewModel.customRecipes;

          return SingleChildScrollView(
            child: Column(
              children: [
                TopMenuBar(currentIndex: 0),
                const SizedBox(height: 16),
                PostSection(
                  title: '많이 본 레시피',
                  titleColor: Colors.red.shade100,
                  posts: mostViewedPosts,
                ),
                const SizedBox(height: 24),
                PostSection(
                  title: '오늘 올라온 레시피',
                  titleColor: Colors.red.shade100,
                  posts: todayShowcasePosts,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
