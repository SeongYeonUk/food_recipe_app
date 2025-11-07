// lib/viewmodels/recipe_viewmodel.dart

import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import './statistics_viewmodel.dart';
import '../models/recipe_model.dart'; // [수정] Ingredient 모델을 위해 import
import '../common/api_client.dart';
import '../models/ingredient_input_model.dart';
import 'package:collection/collection.dart';
import '../models/ingredient_model.dart'; // [추가] Ingredient 모델 import

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

  // [❗️수정] List<String> -> List<Ingredient> 타입으로 변경
  List<Ingredient> _userIngredients = [];

  // --- Getters ---

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

  // [❗️수정] List<String> -> List<Ingredient> 타입으로 변경
  List<Ingredient> get userIngredients => _userIngredients;

  List<Recipe> get customRecipes {
    return _allRecipes.where((r) => r.isCustom || r.isFavorite).toList();
  }

  // [❗️수정] getter가 아닌 일반 변수로 변경 (재계산 로직에서 값을 할당해야 하므로)
  List<Recipe> filteredAiRecipes = [];
  // ---

  List<Recipe> _calculateFilteredAiRecipes() {
    // [❗️수정] 기존 getter 로직을 '계산 함수'로 변경
    if (_userIngredients.isEmpty) {
      return allAiRecipes;
    }

    print("--- 최종 필터링 검증 시작 ---");
    // [❗️수정] List<String> -> List<Ingredient> 이므로 이름만 추출
    print("내 냉장고 재료: ${_userIngredients.map((e) => e.name).toList()}");

    final List<Recipe> result = [];
    // 1. 모든 AI 레시피를 하나씩 확인
    for (final recipe in allAiRecipes) {
      bool isMatchFound = false;
      // 2. 레시피의 모든 재료를 하나씩 확인
      for (final recipeIngredient in recipe.ingredients) {
        // 3. 내 냉장고의 모든 재료를 하나씩 확인
        // [❗️수정] List<String> -> List<Ingredient> 이므로 ing.name 사용
        for (final userIngredient in _userIngredients) {
          // 비교 전, 양쪽의 모든 공백을 제거해서 정확도를 높입니다.
          final cleanRecipeIngredient = recipeIngredient.trim();
          final cleanUserIngredient = userIngredient.name
              .trim(); // [❗️수정] ing.name 사용

          // 👇👇👇 [디버깅 로그] 어떤 단어들이 비교되는지 눈으로 확인합니다. 👇👇👇
          print(
            "  [비교] 레시피 재료: '${cleanRecipeIngredient}' (길이: ${cleanRecipeIngredient.length}) | 내 재료: '${cleanUserIngredient}' (길이: ${cleanUserIngredient.length})",
          );

          // [❗️수정] 레시피 재료명에 내 재료명이 포함되어 있는지 확인
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

  Future<void> loadInitialData() {
    return fetchRecipes();
  }

  // [❗️수정] ProxyProvider가 호출할 '공개' 업데이트 함수
  // (List<String>이 아닌 List<Ingredient>를 받도록 수정)
  void updateUserIngredients(List<Ingredient> newIngredients) {
    // 재료 목록이 실제로 변경되었는지 확인 (단순 비교)
    if (_userIngredients != newIngredients) {
      _userIngredients = newIngredients;
      _recalculateAiRecipes(); // 재료가 업데이트되었으니 AI 추천 재계산
    }
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
        // [❗️수정] API 응답 데이터를 _allRecipes에 저장
        _allRecipes = responseData
            .map((data) => Recipe.fromJson(data))
            .toList();

        // [❗️수정] 레시피 로딩 직후, 현재 재료로 재계산 시도
        _recalculateAiRecipes();
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

  // [❗️수정] AI 추천 레시피를 '재계산'하는 내부 함수
  void _recalculateAiRecipes() {
    // 1. 재료가 없거나 레시피 원본이 없으면 계산 중지
    if (_userIngredients.isEmpty || _allRecipes.isEmpty) {
      filteredAiRecipes = allAiRecipes; // [❗️수정] 재료 없으면 AI 레시피 '전체'를 보여줌
      notifyListeners(); // UI 갱신
      return;
    }

    // 2. [❗️수정] 기존 getter 로직이었던 계산 함수를 호출
    final List<Recipe> recommendations = _calculateFilteredAiRecipes();

    // 3. 최종 결과를 속성에 저장하고 UI 갱신
    filteredAiRecipes = recommendations;
    notifyListeners();
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

  Future<void> addSelectedToFavorites() async {
    final Set<int> idsToAdd = _isAiSelectionMode
        ? _selectedAiRecipeIds
        : _selectedMyRecipeIds;

    if (idsToAdd.isEmpty) return;

    try {
      await _apiClient.post(
        '/api/recipes/favorites',
        body: {'recipeIds': idsToAdd.toList()},
      );
      for (var recipeId in idsToAdd) {
        final recipe = _allRecipes.firstWhereOrNull((r) => r.id == recipeId);
        if (recipe != null) {
          recipe.isFavorite = true;
        }
      }
    } catch (e) {
      print('즐겨찾기 추가 실패: $e');
    } finally {
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

  Future<void> deleteFavorites() async {
    if (_selectedFavoriteRecipeIds.isEmpty) return;

    final idsToDelete = _selectedFavoriteRecipeIds.toList();

    try {
      await _apiClient.delete(
        '/api/recipes/favorites',
        body: {'recipeIds': idsToDelete},
      );

      for (var recipeId in idsToDelete) {
        final recipe = _allRecipes.firstWhereOrNull((r) => r.id == recipeId);
        if (recipe != null) {
          recipe.isFavorite = false;
        }
      }
    } catch (e) {
      print('즐겨찾기 삭제 실패: $e');
    } finally {
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
