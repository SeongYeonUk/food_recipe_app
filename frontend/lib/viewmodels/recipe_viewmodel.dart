// lib/viewmodels/recipe_viewmodel.dart (최종 수정본)

import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import './statistics_viewmodel.dart';
import '../models/recipe_model.dart';
import '../common/api_client.dart';
import '../models/ingredient_input_model.dart';
import 'package:collection/collection.dart';

class RecipeViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Recipe> _allRecipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAiSelectionMode = false;
  bool _isMyRecipeSelectionMode = false;
  bool _isFavoriteSelectionMode = false;
  final Set<int> _selectedAiRecipeIds = {};
  final Set<int> _selectedMyRecipeIds = {};
  final Set<int> _selectedFavoriteRecipeIds = {};
  List<String> _userIngredients = [];

  // [수정] !r.isFavorite 조건을 추가해서, 즐겨찾기로 이동한 레시피는 이 목록에서 제외합니다.
  List<Recipe> get myRecipes =>
      _allRecipes.where((r) => r.isCustom && !r.isFavorite).toList();

  // [수정] !r.isCustom 조건을 삭제해서, '나만의 레시피'도 즐겨찾기 목록에 포함되도록 합니다.
  List<Recipe> get favoriteRecipes =>
      _allRecipes.where((r) => r.isFavorite).toList();

  List<Recipe> get allRecipes => _allRecipes;
  List<Recipe> get allAiRecipes =>
      _allRecipes.where((r) => !r.isCustom).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAiSelectionMode => _isAiSelectionMode;
  bool get isMyRecipeSelectionMode => _isMyRecipeSelectionMode;
  bool get isFavoriteSelectionMode => _isFavoriteSelectionMode;
  Set<int> get selectedAiRecipeIds => _selectedAiRecipeIds;
  Set<int> get selectedMyRecipeIds => _selectedMyRecipeIds;
  Set<int> get selectedFavoriteRecipeIds => _selectedFavoriteRecipeIds;
  List<String> get userIngredients => _userIngredients;

  List<Recipe> get customRecipes {
    return _allRecipes.where((r) => r.isCustom || r.isFavorite).toList();
  }

  // lib/viewmodels/recipe_viewmodel.dart

  // lib/viewmodels/recipe_viewmodel.dart

  List<Recipe> get filteredAiRecipes {
    if (_userIngredients.isEmpty) {
      return allAiRecipes;
    }

    print("--- 최종 필터링 검증 시작 ---");
    print("내 냉장고 재료: $_userIngredients");

    final List<Recipe> result = [];
    // 1. 모든 AI 레시피를 하나씩 확인
    for (final recipe in allAiRecipes) {
      bool isMatchFound = false;
      // 2. 레시피의 모든 재료를 하나씩 확인
      for (final recipeIngredient in recipe.ingredients) {
        // 3. 내 냉장고의 모든 재료를 하나씩 확인
        for (final userIngredient in _userIngredients) {
          // 비교 전, 양쪽의 모든 공백을 제거해서 정확도를 높입니다.
          final cleanRecipeIngredient = recipeIngredient.trim();
          final cleanUserIngredient = userIngredient.trim();

          // 👇👇👇 [디버깅 로그] 어떤 단어들이 비교되는지 눈으로 확인합니다. 👇👇👇
          print(
            "  [비교] 레시피 재료: '${cleanRecipeIngredient}' (길이: ${cleanRecipeIngredient.length}) | 내 재료: '${cleanUserIngredient}' (길이: ${cleanUserIngredient.length})",
          );

          if (cleanRecipeIngredient.contains(cleanUserIngredient)) {
            print("  ✅ 매치 성공!");
            isMatchFound = true;
            break; // 재료 하나라도 찾았으면 다음 레시피로 넘어감
          }
        }
        if (isMatchFound) {
          break; // 재료 하나라도 찾았으면 다음 레시피로 넘어감
        }
      }

      if (isMatchFound) {
        result.add(recipe);
      }
    }
    print("--- 최종 필터링 검증 종료: ${result.length}개 레시피 찾음 ---");
    return result;
  }

  RecipeViewModel() {}
  Future<void> loadInitialData() async {
    if (_allRecipes.isEmpty) {
      await fetchRecipes();
    }
  }

  void updateUserIngredients(List<String> newIngredients) {
    _userIngredients = newIngredients;
    notifyListeners();
  }

  Future<void> fetchRecipes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/recipes');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _allRecipes = responseData
            .map((data) => Recipe.fromJson(data))
            .toList();
      } else {
        throw Exception('레시피 목록 로딩 실패 (코드: ${response.statusCode})');
      }
    } catch (e) {
      _errorMessage = '데이터 로딩 중 오류 발생: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Recipe> fetchRecipeById(int recipeId) async {
    try {
      final response = await _apiClient.get('/api/recipes/$recipeId');
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);
        final Recipe fetchedRecipe = Recipe.fromJson(jsonData);
        final existingIndex = _allRecipes.indexWhere((r) => r.id == recipeId);
        if (existingIndex == -1) {
          _allRecipes.add(fetchedRecipe);
        } else {
          _allRecipes[existingIndex] = fetchedRecipe;
        }
        notifyListeners();
        return fetchedRecipe;
      } else {
        throw Exception('레시피 정보를 불러오는 데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipe details: $e');
      throw Exception('레시피 정보를 불러오는 데 실패했습니다.');
    }
  }

  Future<void> updateReaction(
    int recipeId,
    ReactionState newReaction,
    BuildContext context,
  ) async {
    final recipe = _allRecipes.firstWhereOrNull((r) => r.id == recipeId);
    if (recipe == null) return;

    final previousReaction = recipe.userReaction;
    final previousLikes = recipe.likes;
    String reactionString = 'none';

    if (previousReaction == newReaction) {
      recipe.userReaction = ReactionState.none;
      if (newReaction == ReactionState.liked) recipe.likes--;
    } else {
      if (previousReaction == ReactionState.liked) recipe.likes--;
      recipe.userReaction = newReaction;
      if (newReaction == ReactionState.liked) {
        recipe.likes++;
        reactionString = 'liked';
      } else if (newReaction == ReactionState.disliked) {
        reactionString = 'disliked';
      }
    }

    try {
      await _apiClient.post(
        '/api/recipes/$recipeId/reaction',
        body: {'reaction': reactionString},
      );
      notifyListeners();
      if (context.mounted) {
        Provider.of<StatisticsViewModel>(
          context,
          listen: false,
        ).updateRecipeLikeCount(recipeId, recipe.likes);
      }
    } catch (e) {
      recipe.userReaction = previousReaction;
      recipe.likes = previousLikes;
      notifyListeners();
    }
  }

  void toggleAiSelectionMode() {
    _isAiSelectionMode = !_isAiSelectionMode;
    if (!_isAiSelectionMode) _selectedAiRecipeIds.clear();
    notifyListeners();
  }

  void toggleMyRecipeSelectionMode() {
    _isMyRecipeSelectionMode = !_isMyRecipeSelectionMode;
    if (!_isMyRecipeSelectionMode) _selectedMyRecipeIds.clear();
    notifyListeners();
  }

  void toggleFavoriteSelectionMode() {
    _isFavoriteSelectionMode = !_isFavoriteSelectionMode;
    if (!_isFavoriteSelectionMode) _selectedFavoriteRecipeIds.clear();
    notifyListeners();
  }

  void selectAiRecipe(int recipeId) {
    if (_selectedAiRecipeIds.contains(recipeId))
      _selectedAiRecipeIds.remove(recipeId);
    else
      _selectedAiRecipeIds.add(recipeId);
    notifyListeners();
  }

  void selectMyRecipe(int recipeId) {
    if (_selectedMyRecipeIds.contains(recipeId))
      _selectedMyRecipeIds.remove(recipeId);
    else
      _selectedMyRecipeIds.add(recipeId);
    notifyListeners();
  }

  void selectFavoriteRecipe(int recipeId) {
    if (_selectedFavoriteRecipeIds.contains(recipeId))
      _selectedFavoriteRecipeIds.remove(recipeId);
    else
      _selectedFavoriteRecipeIds.add(recipeId);
    notifyListeners();
  }

  // [수정] AI와 '나만의 레시피' 모두 처리하는 통합 즐겨찾기 추가 함수
  Future<void> addSelectedToFavorites() async {
    // 1. 현재 활성화된 선택 모드에 따라 어떤 ID 목록을 사용할지 결정합니다.
    final Set<int> idsToAdd = _isAiSelectionMode
        ? _selectedAiRecipeIds
        : _selectedMyRecipeIds;

    if (idsToAdd.isEmpty) return;

    try {
      await _apiClient.post(
        '/api/recipes/favorites',
        body: {'recipeIds': idsToAdd.toList()},
      );
      // 2. 성공 시, UI를 즉시 업데이트하기 위해 선택된 레시피들의 isFavorite 상태를 true로 변경
      for (var recipeId in idsToAdd) {
        final recipe = _allRecipes.firstWhereOrNull((r) => r.id == recipeId);
        if (recipe != null) {
          recipe.isFavorite = true;
        }
      }
    } catch (e) {
      print('즐겨찾기 추가 실패: $e');
      // 필요하다면 여기에 에러 발생 시 사용자에게 알려주는 로직 추가
    } finally {
      // 3. 어떤 모드였든, 작업이 끝나면 해당 선택 모드를 해제합니다.
      if (_isAiSelectionMode) {
        toggleAiSelectionMode();
      } else {
        toggleMyRecipeSelectionMode();
      }
    }
  }

  Future<void> deleteMyRecipes() async {
    if (_selectedMyRecipeIds.isEmpty) return;
    final idsToDelete = Set<int>.from(_selectedMyRecipeIds);
    _allRecipes.removeWhere((r) => idsToDelete.contains(r.id) && r.isCustom);
    toggleMyRecipeSelectionMode();
    try {
      await _apiClient.delete(
        '/api/recipes/favorites',
        body: {'recipeIds': idsToDelete.toList()},
      );
    } catch (e) {
      await fetchRecipes();
    }
  }

  // lib/viewmodels/recipe_viewmodel.dart

  // 👇👇👇 이 deleteFavorites 함수를 아래 코드로 교체해주세요. 👇👇👇
  Future<void> deleteFavorites() async {
    if (_selectedFavoriteRecipeIds.isEmpty) return;

    // 1. 삭제할 ID 목록을 미리 복사해둡니다. (가장 중요!)
    final idsToDelete = _selectedFavoriteRecipeIds.toList();

    // 2. 서버에 먼저 삭제 요청을 보냅니다.
    try {
      await _apiClient.delete(
        '/api/recipes/favorites',
        body: {'recipeIds': idsToDelete},
      );

      // 3. 서버 요청이 성공하면, 앱 화면의 상태를 업데이트합니다.
      for (var recipeId in idsToDelete) {
        final recipe = _allRecipes.firstWhereOrNull((r) => r.id == recipeId);
        if (recipe != null) {
          recipe.isFavorite = false;
        }
      }
    } catch (e) {
      print('즐겨찾기 삭제 실패: $e');
      // 에러가 발생하더라도 사용자 경험을 위해 선택 모드는 해제해주는 것이 좋습니다.
    } finally {
      // 4. 성공하든 실패하든, 마지막으로 선택 모드를 해제합니다.
      // (이때 _selectedFavoriteRecipeIds 목록이 초기화됩니다)
      toggleFavoriteSelectionMode();
    }
  }

  Future<void> blockRecipes() async {
    if (_selectedAiRecipeIds.isEmpty) return;
    final idsToBlock = Set<int>.from(_selectedAiRecipeIds);
    toggleAiSelectionMode();
    try {
      await _apiClient.post(
        '/api/recipes/ai-recommend/hide-bulk',
        body: {'recipeIds': idsToBlock.toList()},
      );
      await fetchRecipes();
    } catch (e) {
      await fetchRecipes();
    }
  }

  Future<bool> addCustomRecipe({
    required String title,
    required String description,
    required List<IngredientInputModel> ingredients,
    required List<String> instructions,
    required int time,
    required String imageUrl,
  }) async {
    final ingredientsData = ingredients
        .map(
          (ing) => {
            'name': ing.nameController.text.trim(),
            'amount': ing.amountController.text.trim(),
          },
        )
        .toList();
    final recipeData = {
      'title': title,
      'description': description,
      'ingredients': ingredientsData,
      'instructions': instructions,
      'time': time,
      'imageUrl': imageUrl,
    };
    try {
      await _apiClient.post('/api/recipes', body: recipeData);
      await fetchRecipes();
      return true;
    } catch (e) {
      return false;
    }
  }
}
