import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'community/community_widgets.dart';
import 'community/recipe_showcase_screen.dart';
import 'community/recipe_review_screen.dart';
import '../viewmodels/statistics_viewmodel.dart';
import '../viewmodels/recipe_viewmodel.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen.dart';

class CommunityDetailScreen extends StatelessWidget {
  final String title;
  const CommunityDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: null),
      body: Center(child: Text('$title screen', style: const TextStyle(fontSize: 24))),
    );
  }
}

class CommunityScreen extends StatefulWidget {
  final String? initialSearchQuery;
  final List<String>? initialIngredientNames;

  const CommunityScreen({super.key, this.initialSearchQuery, this.initialIngredientNames});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;
  List<Recipe> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if ((widget.initialSearchQuery ?? '').isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
    final preset = _normalizeIngredientList(widget.initialIngredientNames);
    if (preset.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performBottomSearch(presetTerms: preset);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<String> _normalizeIngredientList(List<String>? source) {
    if (source == null) return const <String>[];
    final seen = <String>{};
    final result = <String>[];
    for (final item in source) {
      final normalized = item.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) result.add(normalized);
    }
    return result;
  }

  List<String> _parseIngredientTokens(String raw) {
    final parts = raw.split('+');
    final seen = <String>{};
    final tokens = <String>[];
    for (final part in parts) {
      final normalized = part.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) tokens.add(normalized);
    }
    return tokens;
  }

  bool _shouldUseIngredientSearch({
    required List<String> tokens,
    required bool forced,
    required String rawQuery,
  }) {
    if (forced) return true;
    if (rawQuery.contains('+')) return true;
    return tokens.length > 1;
  }

  Future<void> _performBottomSearch({List<String>? presetTerms}) async {
    final rawQuery = _searchController.text.trim();
    final tokens = presetTerms ?? _parseIngredientTokens(rawQuery);
    final useIngredientSearch = _shouldUseIngredientSearch(
      tokens: tokens,
      forced: presetTerms != null,
      rawQuery: rawQuery,
    );

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
      _searchResults = [];
    });

    if (useIngredientSearch && tokens.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchError = '재료를 한 개 이상 선택해 주세요.';
      });
      return;
    }

    try {
      List<Recipe> results;
      if (useIngredientSearch && tokens.isNotEmpty) {
        final recipeVm = context.read<RecipeViewModel>();
        results = await recipeVm.searchByIngredientNames(tokens);
      } else {
        final vm = context.read<StatisticsViewModel>();
        final candidates = <Recipe>[
          ...vm.mostViewedRecipes.map((p) => Recipe.basic(id: p.id, name: p.name, likes: p.likeCount)),
          ...vm.todayShowcaseRecipes.map((p) => Recipe.basic(id: p.id, name: p.name, likes: p.likeCount)),
        ];
        final lowerQuery = rawQuery.toLowerCase();
        results = lowerQuery.isEmpty
            ? candidates
            : candidates.where((e) => e.name.toLowerCase().contains(lowerQuery)).toList();
      }
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchError = '선택한 재료로 레시피를 찾는 중 문제가 발생했어요.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _cancelBottomSearch() {
    setState(() {
      _hasSearched = false;
      _searchError = null;
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            TopMenuBar(
              currentIndex: _tabIndex,
              onSelect: (i) => setState(() => _tabIndex = i),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildTabBody(_tabIndex)),
            if (_tabIndex == 0) _buildBottomSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(int index) {
    switch (index) {
      case 0:
        if (_hasSearched) {
          if (_isSearching) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_searchError != null) {
            return Center(child: Text(_searchError!));
          }
          if (_searchResults.isEmpty) {
            return const Center(child: Text('검색 결과가 없습니다.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final item = _searchResults[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        recipe: item,
                        userIngredients: const [],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const RecipeShowcaseSection();
      case 1:
        return const RecipeReviewSection();
      case 2:
        return const Center(child: Text('Coming soon (오늘의 레시피)'));
      case 3:
        return const Center(child: Text('Coming soon (전문가 레시피)'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: '레시피 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFFAF7F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF6F5B53), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF6F5B53), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF6F5B53), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              onSubmitted: (_) => _performBottomSearch(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            height: 44,
            child: ElevatedButton(
              onPressed: _performBottomSearch,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: const Color(0xFFFFEEE7),
                foregroundColor: const Color(0xFF6F5B53),
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: const Icon(Icons.arrow_forward),
            ),
          ),
          if (_hasSearched) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: _cancelBottomSearch,
              child: const Text('취소'),
            ),
          ],
        ],
      ),
    );
  }
}

