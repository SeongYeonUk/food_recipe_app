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
    return Scaffold(
      appBar: AppBar(title: const Text('레시피 자랑')),
      body: const RecipeShowcaseSection(),
    );
  }
}

// Section-only widget (no Scaffold/AppBar). Use inside CommunityScreen.
class RecipeShowcaseSection extends StatefulWidget {
  const RecipeShowcaseSection({super.key});

  @override
  State<RecipeShowcaseSection> createState() => _RecipeShowcaseSectionState();
}

class _RecipeShowcaseSectionState extends State<RecipeShowcaseSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<StatisticsViewModel>().fetchAllStatistics();
      } catch (_) {}
    });
  }

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
            child: Column(
              children: [
                const SizedBox(height: 8),
                ShowcasePostSection(
                  title: 'Today Showcase',
                  titleColor: Colors.red,
                  posts: viewModel.mostViewedRecipes
                      .map((p) => Recipe.basic(id: p.id, name: p.name, likes: p.likeCount))
                      .toList(),
                ),
                const SizedBox(height: 24),
                ShowcasePostSection(
                  title: 'Today Showcase',
                  titleColor: Colors.yellow,
                  posts: viewModel.todayShowcaseRecipes
                      .map((p) => Recipe.basic(id: p.id, name: p.name, likes: p.likeCount))
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

