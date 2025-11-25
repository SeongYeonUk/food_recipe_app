import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';
import 'create_recipe_screen.dart';
import 'recipe_detail_screen.dart';

/// AI/내 레시피/즐겨찾기 리스트 + 선택 모드 + 카드 토글(영양/가격)
class RecipeRecommendationScreen extends StatefulWidget {
  const RecipeRecommendationScreen({super.key});

  @override
  State<RecipeRecommendationScreen> createState() =>
      _RecipeRecommendationScreenState();
}

class _RecipeRecommendationScreenState
    extends State<RecipeRecommendationScreen> {
  String _expandedSection = 'ai';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeViewModel>().fetchRecommendedRecipes();
    });
  }

  void _toggleSection(String sectionName) {
    setState(() {
      _expandedSection = _expandedSection == sectionName ? '' : sectionName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer<RecipeViewModel>(
          builder: (context, viewModel, child) {
            return RefreshIndicator(
              onRefresh: () => viewModel.fetchRecommendedRecipes(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_expandedSection == 'ai')
                      Expanded(
                        child: _buildExpandedSection(context, viewModel, 'ai'),
                      )
                    else
                      _buildCollapsedSection(context, viewModel, 'ai'),
                    const SizedBox(height: 16),
                    if (_expandedSection == 'my')
                      Expanded(
                        child: _buildExpandedSection(context, viewModel, 'my'),
                      )
                    else
                      _buildCollapsedSection(context, viewModel, 'my'),
                    const SizedBox(height: 16),
                    if (_expandedSection == 'favorite')
                      Expanded(
                        child: _buildExpandedSection(
                          context,
                          viewModel,
                          'favorite',
                        ),
                      )
                    else
                      _buildCollapsedSection(context, viewModel, 'favorite'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpandedSection(
    BuildContext context,
    RecipeViewModel viewModel,
    String sectionType,
  ) {
    final sectionData = _getSectionData(viewModel, sectionType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sectionData['borderColor'], width: 2),
      ),
      child: Column(
        children: [
          _buildSectionHeader(context, viewModel, sectionType),
          const Divider(height: 1, thickness: 1, indent: 12, endIndent: 12),
          Expanded(
            child: (viewModel.isLoading &&
                    (sectionData['recipes'] as List).isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : ((sectionData['recipes'] as List).isEmpty)
                    ? const Center(
                        child: Text(
                          '레시피가 없습니다.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount:
                            (sectionData['recipes'] as List<Recipe>).length,
                        itemBuilder: (context, index) {
                          final recipe =
                              (sectionData['recipes'] as List<Recipe>)[index];
                          return _RecipeListItem(
                            recipe: recipe,
                            isSelectionMode: sectionData['isSelectionMode'],
                            isSelected: (sectionData['selectedIds'] as Set<int>)
                                .contains(recipe.id),
                            onTap: () => sectionData['isSelectionMode']
                                ? (sectionData['onSelectRecipe']
                                        as Function(int))(
                                    recipe.id,
                                  )
                                : _navigateToDetail(context, viewModel, recipe),
                          );
                        },
                      ),
          ),
          if (sectionData['isSelectionMode'])
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _buildActionButtons(context, viewModel, sectionType),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSection(
    BuildContext context,
    RecipeViewModel viewModel,
    String sectionType,
  ) {
    final sectionData = _getSectionData(viewModel, sectionType);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sectionData['borderColor'], width: 2),
      ),
      child: _buildSectionHeader(context, viewModel, sectionType),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    RecipeViewModel viewModel,
    String sectionType,
  ) {
    final sectionData = _getSectionData(viewModel, sectionType);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      title: Text(
        sectionData['title'],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      onTap: sectionData['onHeaderTap'],
      trailing: GestureDetector(
        onTap: sectionData['onToggleSelectionMode'],
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            sectionData['isSelectionMode'] ? Icons.close : Icons.add,
            size: 22,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getSectionData(
    RecipeViewModel viewModel,
    String sectionType,
  ) {
    switch (sectionType) {
      case 'my':
        return {
          'title': '내 레시피',
          'recipes': viewModel.myRecipes,
          'borderColor': const Color(0xFFC8E6C9),
          'isSelectionMode': viewModel.isMyRecipeSelectionMode,
          'onToggleSelectionMode': viewModel.toggleMyRecipeSelectionMode,
          'onSelectRecipe': viewModel.selectMyRecipe,
          'selectedIds': viewModel.selectedMyRecipeIds,
          'onHeaderTap': () => _toggleSection('my'),
        };
      case 'favorite':
        return {
          'title': '즐겨찾기',
          'recipes': viewModel.favoriteRecipes,
          'borderColor': const Color(0xFFFFECB3),
          'isSelectionMode': viewModel.isFavoriteSelectionMode,
          'onToggleSelectionMode': viewModel.toggleFavoriteSelectionMode,
          'onSelectRecipe': viewModel.selectFavoriteRecipe,
          'selectedIds': viewModel.selectedFavoriteRecipeIds,
          'onHeaderTap': () => _toggleSection('favorite'),
        };
      case 'ai':
      default:
        return {
          'title': 'AI 추천 레시피',
          'recipes': viewModel.filteredAiRecipes,
          'borderColor': const Color(0xFFB3E5FC),
          'isSelectionMode': viewModel.isAiSelectionMode,
          'onToggleSelectionMode': viewModel.toggleAiSelectionMode,
          'onSelectRecipe': viewModel.selectAiRecipe,
          'selectedIds': viewModel.selectedAiRecipeIds,
          'onHeaderTap': () => _toggleSection('ai'),
        };
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    RecipeViewModel viewModel,
    String type,
  ) {
    if (type == 'ai') {
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              text: '즐겨찾기 추가',
              color: const Color(0xFFFFD54F),
              onPressed: viewModel.selectedAiRecipeIds.isNotEmpty
                  ? viewModel.addSelectedToFavorites
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              text: '이 레시피 안 볼래요',
              color: const Color(0xFFF06292),
              onPressed: viewModel.selectedAiRecipeIds.isNotEmpty
                  ? viewModel.blockRecipes
                  : null,
            ),
          ),
        ],
      );
    } else if (type == 'my') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  text: '레시피 만들기',
                  color: const Color(0xFFA5D6A7),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateRecipeScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  text: '즐겨찾기 추가',
                  color: const Color(0xFFFFD54F),
                  onPressed: viewModel.selectedMyRecipeIds.isNotEmpty
                      ? viewModel.addSelectedToFavorites
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  text: '레시피 공유',
                  color: const Color(0xFF90CAF9),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('공유 기능 준비 중입니다.')),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  text: '레시피 삭제',
                  color: const Color(0xFFF06292),
                  onPressed: viewModel.selectedMyRecipeIds.isNotEmpty
                      ? viewModel.deleteMyRecipes
                      : null,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // favorite
      return _buildActionButton(
        text: '즐겨찾기 삭제',
        color: const Color(0xFFF06292),
        onPressed: viewModel.selectedFavoriteRecipeIds.isNotEmpty
            ? viewModel.deleteFavorites
            : null,
      );
    }
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      child: Text(text),
    );
  }

  void _navigateToDetail(
    BuildContext context,
    RecipeViewModel viewModel,
    Recipe recipe,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: viewModel,
          child: RecipeDetailScreen(
            recipe: recipe,
            userIngredients:
                viewModel.userIngredients.map((ing) => ing.name).toList(),
          ),
        ),
      ),
    );
  }
}

// ------------------ 리스트 카드 ------------------
class _RecipeListItem extends StatefulWidget {
  final Recipe recipe;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  const _RecipeListItem({
    required this.recipe,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RecipeListItem> createState() => _RecipeListItemState();
}

class _RecipeListItemState extends State<_RecipeListItem> {
  bool _showNutrition = false;
  bool _showPrice = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(8),
          border: widget.isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(
                      widget.isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: widget.isSelected ? Colors.blue : Colors.grey,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '주요 재료: ${recipe.ingredients.join(', ')}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    _TogglePillMini(
                      label: '영양',
                      icon: Icons.health_and_safety_outlined,
                      isOn: _showNutrition,
                      onTap: () =>
                          setState(() => _showNutrition = !_showNutrition),
                    ),
                    _TogglePillMini(
                      label: '가격',
                      icon: Icons.sell_outlined,
                      isOn: _showPrice,
                      onTap: () => setState(() => _showPrice = !_showPrice),
                    ),
                  ],
                ),
              ],
            ),
            if (_showNutrition || _showPrice) ...[
              const SizedBox(height: 8),
              _buildInfoBlock(recipe),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(Recipe recipe) {
    final hasNutri = recipe.totalKcal != null ||
        recipe.totalCarbsG != null ||
        recipe.totalProteinG != null ||
        recipe.totalFatG != null ||
        recipe.totalSodiumMg != null;
    final hasPrice =
        recipe.estimatedMinPriceKrw != null || recipe.estimatedMaxPriceKrw != null;

    if ((_showNutrition && !hasNutri) && (_showPrice && !hasPrice)) {
      return const Text(
        '영양/가격 정보가 없습니다.',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }

    String numStr(double? v, {int digits = 1, String unit = ''}) {
      if (v == null) return '-';
      return '${v.toStringAsFixed(digits)}$unit';
    }

    String priceStr(double? min, double? max) {
      if (min == null && max == null) return '-';
      if (min != null && max != null) {
        return '${min.toStringAsFixed(0)} ~ ${max.toStringAsFixed(0)}원';
      }
      return '${(min ?? max)?.toStringAsFixed(0)}원';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showNutrition) ...[
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _chip('칼로리', numStr(recipe.totalKcal, unit: ' kcal')),
                _chip('탄수화물', numStr(recipe.totalCarbsG, unit: ' g')),
                _chip('단백질', numStr(recipe.totalProteinG, unit: ' g')),
                _chip('지방', numStr(recipe.totalFatG, unit: ' g')),
                _chip('나트륨', numStr(recipe.totalSodiumMg, unit: ' mg')),
              ],
            ),
          ],
          if (_showNutrition && _showPrice) const SizedBox(height: 8),
          if (_showPrice)
            Text(
              '예상 가격: ${priceStr(recipe.estimatedMinPriceKrw, recipe.estimatedMaxPriceKrw)}',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TogglePillMini extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isOn;
  final VoidCallback onTap;

  const _TogglePillMini({
    required this.label,
    required this.icon,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 16,
        color: isOn ? Colors.white : Colors.brown.shade400,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isOn ? Colors.white : Colors.brown.shade400,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.brown.shade400,
        backgroundColor: isOn ? Colors.brown.shade300 : Colors.white,
        side: BorderSide(color: Colors.brown.shade300, width: 1.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
