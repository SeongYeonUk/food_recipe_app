import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';
import 'create_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipeRecommendationScreen extends StatefulWidget {
  const RecipeRecommendationScreen({super.key});

  @override
  State<RecipeRecommendationScreen> createState() => _RecipeRecommendationScreenState();
}

class _RecipeRecommendationScreenState extends State<RecipeRecommendationScreen> {
  // 처음에는 'AI 추천 레시피' 섹션이 펼쳐져 있도록 설정
  String _expandedSection = 'ai';

  void _toggleSection(String sectionName) {
    setState(() {
      if (_expandedSection == sectionName) {
        _expandedSection = ''; // 이미 열린 섹션을 누르면 닫기
      } else {
        _expandedSection = sectionName; // 다른 섹션을 누르면 열기
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("레시피 추천"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<RecipeViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: () => viewModel.fetchRecipes(),
            // [핵심 수정] ListView 대신 Column을 사용하여 레이아웃을 제어합니다.
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 'AI 추천 레시피' 섹션
                  if (_expandedSection == 'ai')
                    Expanded(child: _buildExpandedSection(context, viewModel, 'ai'))
                  else
                    _buildCollapsedSection(context, viewModel, 'ai'),

                  const SizedBox(height: 16),

                  // '나만의 레시피' 섹션
                  if (_expandedSection == 'my')
                    Expanded(child: _buildExpandedSection(context, viewModel, 'my'))
                  else
                    _buildCollapsedSection(context, viewModel, 'my'),

                  const SizedBox(height: 16),

                  // '즐겨찾기' 섹션
                  if (_expandedSection == 'favorite')
                    Expanded(child: _buildExpandedSection(context, viewModel, 'favorite'))
                  else
                    _buildCollapsedSection(context, viewModel, 'favorite'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // [신규] 펼쳐진 상태의 섹션을 만드는 위젯
  Widget _buildExpandedSection(BuildContext context, RecipeViewModel viewModel, String sectionType) {
    final Map<String, dynamic> sectionData = _getSectionData(viewModel, sectionType);

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
          // [핵심 수정] ListView가 남은 공간을 모두 채우도록 Expanded로 감쌉니다.
          Expanded(
            child: (viewModel.isLoading && (sectionData['recipes'] as List).isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : ((sectionData['recipes'] as List).isEmpty)
                ? const Center(child: Text("레시피가 없습니다.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: (sectionData['recipes'] as List<Recipe>).length,
              itemBuilder: (context, index) {
                final recipe = (sectionData['recipes'] as List<Recipe>)[index];
                return _RecipeListItem(
                  recipe: recipe,
                  isSelectionMode: sectionData['isSelectionMode'],
                  isSelected: (sectionData['selectedIds'] as Set<int>).contains(recipe.id),
                  onTap: () => sectionData['isSelectionMode']
                      ? (sectionData['onSelectRecipe'] as Function(int))(recipe.id)
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

  // [신규] 접힌 상태의 섹션(헤더만)을 만드는 위젯
  Widget _buildCollapsedSection(BuildContext context, RecipeViewModel viewModel, String sectionType) {
    final Map<String, dynamic> sectionData = _getSectionData(viewModel, sectionType);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sectionData['borderColor'], width: 2),
      ),
      child: _buildSectionHeader(context, viewModel, sectionType),
    );
  }

  // [신규] 모든 섹션에서 공통으로 사용하는 헤더 위젯
  Widget _buildSectionHeader(BuildContext context, RecipeViewModel viewModel, String sectionType) {
    final Map<String, dynamic> sectionData = _getSectionData(viewModel, sectionType);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      title: Text(sectionData['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      onTap: sectionData['onHeaderTap'],
      trailing: GestureDetector(
        onTap: sectionData['onToggleSelectionMode'],
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
          child: Icon(sectionData['isSelectionMode'] ? Icons.close : Icons.add, size: 22),
        ),
      ),
    );
  }

  // [신규] 섹션 타입에 맞는 데이터를 반환하는 헬퍼 함수
  Map<String, dynamic> _getSectionData(RecipeViewModel viewModel, String sectionType) {
    switch (sectionType) {
      case 'my':
        return {
          'title': '나만의 레시피', 'recipes': viewModel.myRecipes, 'borderColor': const Color(0xFFC8E6C9),
          'isSelectionMode': viewModel.isMyRecipeSelectionMode, 'onToggleSelectionMode': viewModel.toggleMyRecipeSelectionMode,
          'onSelectRecipe': viewModel.selectMyRecipe, 'selectedIds': viewModel.selectedMyRecipeIds,
          'onHeaderTap': () => _toggleSection('my'),
        };
      case 'favorite':
        return {
          'title': '즐겨찾기', 'recipes': viewModel.favoriteRecipes, 'borderColor': const Color(0xFFFFECB3),
          'isSelectionMode': viewModel.isFavoriteSelectionMode, 'onToggleSelectionMode': viewModel.toggleFavoriteSelectionMode,
          'onSelectRecipe': viewModel.selectFavoriteRecipe, 'selectedIds': viewModel.selectedFavoriteRecipeIds,
          'onHeaderTap': () => _toggleSection('favorite'),
        };
      case 'ai':
      default:
        return {
          'title': 'AI 추천 레시피', 'recipes': viewModel.filteredAiRecipes, 'borderColor': const Color(0xFFB3E5FC),
          'isSelectionMode': viewModel.isAiSelectionMode, 'onToggleSelectionMode': viewModel.toggleAiSelectionMode,
          'onSelectRecipe': viewModel.selectAiRecipe, 'selectedIds': viewModel.selectedAiRecipeIds,
          'onHeaderTap': () => _toggleSection('ai'),
        };
    }
  }

  // 버튼 UI와 로직은 이전과 동일하게 유지
  Widget _buildActionButtons(BuildContext context, RecipeViewModel viewModel, String type) {
    if (type == 'ai') {
      return Row(children: [
        Expanded(child: _buildActionButton(text: '즐겨찾기 추가', color: const Color(0xFFFFD54F), onPressed: viewModel.selectedAiRecipeIds.isNotEmpty ? viewModel.addFavorites : null)),
        const SizedBox(width: 8),
        Expanded(child: _buildActionButton(text: '레시피 추천 안함', color: const Color(0xFFF06292), onPressed: viewModel.selectedAiRecipeIds.isNotEmpty ? viewModel.blockRecipes : null)),
      ]);
    } else if (type == 'my') {
      return Column(children: [
        Row(children: [
          Expanded(child: _buildActionButton(text: '레시피 만들기', color: const Color(0xFFA5D6A7), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRecipeScreen())))),
          const SizedBox(width: 8),
          Expanded(child: _buildActionButton(text: '즐겨찾기 추가', color: const Color(0xFFFFD54F), onPressed: viewModel.selectedMyRecipeIds.isNotEmpty ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('해당 기능은 준비 중입니다.'))) : null)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildActionButton(text: '레시피 공유', color: const Color(0xFF90CAF9), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('레시피 공유 기능은 준비 중입니다.'))))),
          const SizedBox(width: 8),
          Expanded(child: _buildActionButton(text: '레시피 삭제', color: const Color(0xFFF06292), onPressed: viewModel.selectedMyRecipeIds.isNotEmpty ? viewModel.deleteMyRecipes : null)),
        ]),
      ]);
    } else { // favorite
      return _buildActionButton(text: '즐겨찾기 삭제', color: const Color(0xFFF06292), onPressed: viewModel.selectedFavoriteRecipeIds.isNotEmpty ? viewModel.deleteFavorites : null);
    }
  }

  Widget _buildActionButton({required String text, required Color color, VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87, backgroundColor: color, disabledBackgroundColor: color.withOpacity(0.5),
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      child: Text(text),
    );
  }

  void _navigateToDetail(BuildContext context, RecipeViewModel viewModel, Recipe recipe) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: RecipeDetailScreen(recipe: recipe, userIngredients: viewModel.userIngredients),
      ),
    ));
  }
}

class _RecipeListItem extends StatelessWidget {
  final Recipe recipe; final bool isSelectionMode; final bool isSelected; final VoidCallback onTap;
  const _RecipeListItem({required this.recipe, required this.isSelectionMode, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Row(children: [
          if (isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? Colors.blue : Colors.grey),
            ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('필요 재료: ${recipe.ingredients.join(', ')}', style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
            ]),
          ),
        ]),
      ),
    );
  }
}

