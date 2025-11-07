import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // [추가] 뷰모델 사용을 위해 추가
import '../viewmodels/recipe_viewmodel.dart'; // [추가] 레시피 뷰모델 import
import '../models/recipe_model.dart'; // [추가] Recipe 모델 import
import 'community/community_data.dart';
import './recipe_detail_screen.dart';

// [수정 안함] CommunityDetailScreen 위젯 (기존과 동일)
class CommunityDetailScreen extends StatelessWidget {
  final String title;
  const CommunityDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title 화면', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

// [수정 안함] CommunityScreen StatefulWidget (기존과 동일)
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;

  // [수정] 검색 결과를 BasicRecipeItem이 아닌 'Recipe' 모델로 받도록 변경
  // List<BasicRecipeItem> _searchResults = []; // <- 기존 코드
  List<Recipe> _searchResults = []; // <- 수정된 코드

  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // [community_screen.dart]의 _performSearch 함수

  Future<void> _performSearch() async {
    final query = _searchController.text.toLowerCase();

    // 키보드 숨기기
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = []; // 검색 시작 시 목록 비우기
    });

    try {
      // 1. Provider를 통해 RecipeViewModel에 접근
      final recipeViewModel = Provider.of<RecipeViewModel>(
        context,
        listen: false,
      );

      // 2. ViewModel에서 '모든 AI 레시피 목록'을 가져옵니다.
      // [❗️핵심 수정] filteredAiRecipes -> allAiRecipes 로 변경
      final List<Recipe> allAiRecipes = recipeViewModel.allAiRecipes;

      // 3. '모든 AI 레시피' 목록을 사용자의 '검색어(query)'로 필터링
      List<Recipe> finalFilteredList;
      if (query.isEmpty) {
        // 검색어가 없으면 '모든 AI 레시피' 목록 전체를 보여줌
        finalFilteredList = allAiRecipes;
      } else {
        // 검색어가 있으면, '모든 AI 레시피' 목록 내에서 이름 검색
        finalFilteredList = allAiRecipes
            .where((recipe) => recipe.name.toLowerCase().contains(query))
            .toList();
      }

      // 4. 상태 업데이트
      setState(() {
        _searchResults = finalFilteredList;
      });
    } catch (e) {
      print('AI 레시피 검색 중 에러: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [수정 안함] _cancelSearch 함수 (기존과 동일)
  void _cancelSearch() {
    setState(() {
      _hasSearched = false;
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  // [수정 안함] _navigateToScreen 함수 (기존과 동일)
  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티')),
      body: Column(
        children: [
          // --- 검색 결과 or 배경 GridView ---
          Expanded(
            child: _hasSearched
                ? _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults.isEmpty
                      ? const Center(
                          child: Text('AI 추천 레시피 중 일치하는 결과가 없습니다.'),
                        ) // [수정] 텍스트 변경
                      : ListView.builder(
                          // [수정] 검색 결과 리스트 UI
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            // 'item'은 이제 BasicRecipeItem이 아닌 'Recipe' 객체입니다.
                            final item = _searchResults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: item.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: Image.network(
                                          // [수정 안함] imageUrl 필드는 이름이 동일하다고 가정
                                          item.imageUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.restaurant_menu,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                title: Text(
                                  // [수정] recipeNameKo -> name
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    // 'recipe.ingredients' 리스트의 각 재료를 쉼표(,)로 연결하여 표시합니다.
                                    '필요 재료: ${item.ingredients.join(', ')}',
                                    maxLines: 1, // 한 줄로 표시
                                    overflow:
                                        TextOverflow.ellipsis, // 길면 ... 처리
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ), // 추천 탭과 유사한 스타일
                                  ),
                                ),
                                onTap: () {
                                  // 1. Provider를 통해 ViewModel에 접근합니다.
                                  final viewModel =
                                      Provider.of<RecipeViewModel>(
                                        context,
                                        listen: false,
                                      );

                                  // 2. '레시피 추천' 탭에서 사용한 것과 동일한 방식으로
                                  //    ChangeNotifierProvider.value와 함께 상세 화면으로 이동시킵니다.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider.value(
                                        value: viewModel,
                                        child: RecipeDetailScreen(
                                          recipe:
                                              item, // 'item'이 사용자가 클릭한 Recipe 객체입니다.
                                          userIngredients: viewModel
                                              .userIngredients
                                              .map((ing) => ing.name)
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        )
                : Padding(
                    // [수정 안함] 검색 전 커뮤니티 카테고리 (기존과 동일)
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: communityCategories.length,
                      itemBuilder: (context, index) {
                        final category = communityCategories[index];
                        return _buildCategoryItem(
                          context,
                          label: category['label'],
                          color: category['color'],
                          onTap: () =>
                              _navigateToScreen(context, category['screen']),
                        );
                      },
                    ),
                  ),
          ),

          // --- 하단 검색창 + 취소 버튼 --- (기존과 동일)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'AI 추천 레시피 검색...', // [수정] 힌트 텍스트 변경
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _performSearch, // [수정 안함] 변경된 함수 호출
                      ),
                    ),
                    onSubmitted: (value) =>
                        _performSearch(), // [수정 안함] 변경된 함수 호출
                  ),
                ),
                if (_hasSearched) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _cancelSearch,
                    child: const Text(
                      '취소',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // [수정 안함] _buildCategoryItem 헬퍼 위젯 (기존과 동일)
  Widget _buildCategoryItem(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
