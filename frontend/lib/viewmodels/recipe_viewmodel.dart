// lib/viewmodels/recipe_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../common/api_client.dart';
import '../models/ingredient_input_model.dart';

class RecipeViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Recipe> _allRecipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAiSelectionMode = false;
  bool _isCustomSelectionMode = false;
  final Set<int> _selectedAiRecipeIds = {};
  final Set<int> _selectedCustomRecipeIds = {};
  List<String> _userIngredients = [];

  // [솔루션] '나만의 레시피'는 이제 isCustom 또는 isFavorite(백엔드 필드)를 기준으로 합니다.
  List<Recipe> get customRecipes {
    return _allRecipes.where((r) => r.isCustom || r.isFavorite).toList();
  }

  List<Recipe> get allAiRecipes => _allRecipes.where((r) => !r.isCustom).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAiSelectionMode => _isAiSelectionMode;
  bool get isCustomSelectionMode => _isCustomSelectionMode;
  Set<int> get selectedAiRecipeIds => _selectedAiRecipeIds;
  Set<int> get selectedCustomRecipeIds => _selectedCustomRecipeIds;
  List<String> get userIngredients => _userIngredients;

  List<Recipe> get filteredAiRecipes {
    if (_userIngredients.isEmpty) return allAiRecipes;
    return allAiRecipes.where((recipe) {
      return recipe.ingredients.any((recipeIngredient) {
        final coreIngredient = recipeIngredient.split(' ')[0];
        return _userIngredients.contains(coreIngredient);
      });
    }).toList();
  }

  RecipeViewModel() {
    fetchRecipes();
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
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _allRecipes = responseData.map((data) => Recipe.fromJson(data)).toList();
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

  Future<void> updateReaction(int recipeId, ReactionState newReaction) async {
    final recipe = _allRecipes.firstWhere((r) => r.id == recipeId);
    final previousReaction = recipe.userReaction;
    final previousLikes = recipe.likes;
    String reactionString = 'none';
    if (previousReaction == newReaction) {
      recipe.userReaction = ReactionState.none;
      reactionString = 'none';
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
    notifyListeners();
    try {
      await _apiClient.post('/api/recipes/$recipeId/reaction', body: {'reaction': reactionString});
    } catch (e) {
      print('반응 업데이트 실패: $e');
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

  void toggleCustomSelectionMode() {
    _isCustomSelectionMode = !_isCustomSelectionMode;
    if (!_isCustomSelectionMode) _selectedCustomRecipeIds.clear();
    notifyListeners();
  }

  void selectAiRecipe(int recipeId) {
    if (_selectedAiRecipeIds.contains(recipeId)) _selectedAiRecipeIds.remove(recipeId);
    else _selectedAiRecipeIds.add(recipeId);
    notifyListeners();
  }

  void selectCustomRecipe(int recipeId) {
    if (_selectedCustomRecipeIds.contains(recipeId)) _selectedCustomRecipeIds.remove(recipeId);
    else _selectedCustomRecipeIds.add(recipeId);
    notifyListeners();
  }

  // [솔루션] '즐겨찾기 추가'는 더 이상 '좋아요'와 관련이 없습니다.
  Future<void> addFavorites() async {
    if (_selectedAiRecipeIds.isEmpty) return;
    try {
      await _apiClient.post('/api/recipes/favorites', body: {'recipeIds': _selectedAiRecipeIds.toList()});
      // 성공 시, UI를 즉시 업데이트하기 위해 선택된 레시피들의 isFavorite 상태를 true로 변경
      for (var recipeId in _selectedAiRecipeIds) {
        final recipe = _allRecipes.firstWhere((r) => r.id == recipeId);
        recipe.isFavorite = true;
      }
    } catch (e) {
      print('즐겨찾기 추가 실패: $e');
    } finally {
      toggleAiSelectionMode(); // 선택 모드 해제 및 UI 새로고침
    }
  }

  Future<void> addFavoritesByIds(List<int> recipeIds) async {
    if (recipeIds.isEmpty) return;
    await _apiClient.post('/api/recipes/favorites', body: {'recipeIds': recipeIds});
    await fetchRecipes();
  }

  Future<void> blockRecipes() async {
    if (_selectedAiRecipeIds.isEmpty) return;
    await _apiClient.post('/api/recipes/ai-recommend/hide-bulk', body: {'recipeIds': _selectedAiRecipeIds.toList()});
    toggleAiSelectionMode();
    await fetchRecipes();
  }

  Future<void> deleteCustomRecipes() async {
    if (_selectedCustomRecipeIds.isEmpty) return;
    await _apiClient.delete('/api/recipes/favorites', body: {'recipeIds': _selectedCustomRecipeIds.toList()});
    toggleCustomSelectionMode();
    await fetchRecipes();
  }

  Future<bool> addCustomRecipe({
    required String title,
    required String description,
    required List<IngredientInputModel> ingredients,
    required List<String> instructions,
    required int time,
    required String imageUrl,
  }) async {
    final ingredientsData = ingredients.map((ing) => {
      'name': ing.nameController.text.trim(),
      'amount': ing.amountController.text.trim(),
    }).toList();
    final recipeData = {
      'title': title,
      'description': description,
      'ingredients': ingredientsData,
      'instructions': instructions,
      'time': time,
      'imageUrl': imageUrl,
      'custom': true,
    };
    final response = await _apiClient.post('/api/recipes', body: recipeData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      await fetchRecipes();
      return true;
    }
    return false;
  }
}


