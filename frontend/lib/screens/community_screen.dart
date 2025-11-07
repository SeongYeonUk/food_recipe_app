import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';
import 'community/community_widgets.dart';
import 'recipe_detail_screen.dart';

class CommunityDetailScreen extends StatelessWidget {
  final String title;
  const CommunityDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title 화면', style: const TextStyle(fontSize: 24))),
    );
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  bool _hasSearched = false;
  List<Recipe> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim().toLowerCase();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      final vm = context.read<RecipeViewModel>();
      if (vm.allRecipes.isEmpty && !vm.isLoading) {
        await vm.fetchRecipes();
      }
      final List<Recipe> allAi = vm.allAiRecipes;
      final results = query.isEmpty
          ? allAi
          : allAi.where((r) => r.name.toLowerCase().contains(query)).toList();
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cancelSearch() {
    setState(() {
      _hasSearched = false;
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티')),
      body: Column(
        children: [
          Expanded(
            child: _hasSearched
                ? _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text('AI 추천 레시피에서 일치하는 결과가 없습니다.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '주요 재료: ${item.ingredients.join(', ')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailScreen(
                                        recipe: item,
                                        userIngredients: context
                                            .read<RecipeViewModel>()
                                            .userIngredients
                                            .map((e) => e.name)
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                : Column(
                    children: [
                      TopMenuBar(currentIndex: 0),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'AI 추천 레시피 검색',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
                if (_hasSearched) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _cancelSearch,
                    child: const Text('취소'),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}
