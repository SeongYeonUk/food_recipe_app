import 'package:flutter/material.dart';
import 'community/community_data.dart';
import '../services/api_service.dart';
import '../models/basic_recipe_item.dart';

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

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  List<BasicRecipeItem> _searchResults = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.searchRecipes(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('검색 중 에러: $e');
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
                      ? const Center(child: Text('검색 결과가 없습니다.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
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
                                  item.recipeNameKo,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    item.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                onTap: () {
                                  print('${item.recipeNameKo} 상세 보기');
                                },
                              ),
                            );
                          },
                        )
                : Padding(
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

          // --- 하단 검색창 + 취소 버튼 ---
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
                      hintText: '레시피 또는 재료를 검색하세요',
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
                        onPressed: _performSearch,
                      ),
                    ),
                    onSubmitted: (value) => _performSearch(),
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
