// lib/viewmodels/recipe_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../common/api_client.dart';

class RecipeViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Recipe> _aiRecipes = [];
  List<Recipe> _customRecipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAiSelectionMode = false;
  bool _isCustomSelectionMode = false;
  final Set<int> _selectedAiRecipeIds = {};   // [수정] Set<String> -> Set<int>
  final Set<int> _selectedCustomRecipeIds = {}; // [수정] Set<String> -> Set<int>
  List<String> _userIngredients = [];

  List<Recipe> get customRecipes => _customRecipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAiSelectionMode => _isAiSelectionMode;
  bool get isCustomSelectionMode => _isCustomSelectionMode;
  Set<int> get selectedAiRecipeIds => _selectedAiRecipeIds;
  Set<int> get selectedCustomRecipeIds => _selectedCustomRecipeIds;
  List<String> get userIngredients => _userIngredients;
  List<Recipe> get allAiRecipes => _aiRecipes;

  List<Recipe> get filteredAiRecipes {
    if (_userIngredients.isEmpty) return _aiRecipes;
    return _aiRecipes.where((recipe) {
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
      final aiFuture = _apiClient.get('/api/recipes/ai-recommend');
      final customFuture = _apiClient.get('/api/recipes/my');
      final responses = await Future.wait([aiFuture, customFuture]);

      if (responses[0].statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(responses[0].bodyBytes));
        _aiRecipes = responseData.map((data) => Recipe.fromJson(data)).toList();
      } else {
        throw Exception('AI 추천 레시피 로딩 실패 (코드: ${responses[0].statusCode})');
      }

      if (responses[1].statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(responses[1].bodyBytes));
        _customRecipes = responseData.map((data) => Recipe.fromJson(data)).toList();
      } else {
        throw Exception('나만의 레시피 로딩 실패 (코드: ${responses[1].statusCode})');
      }
    } catch (e) {
      _errorMessage = '데이터 로딩 중 오류 발생: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateReaction(int recipeId, ReactionState newReaction) {
    // TODO: 백엔드에 좋아요/싫어요 API 추가 요청 필요
    final recipe = [..._aiRecipes, ..._customRecipes].firstWhere((r) => r.id == recipeId);
    final previousReaction = recipe.userReaction;
    if (previousReaction == newReaction) {
      recipe.userReaction = ReactionState.none;
      if (newReaction == ReactionState.liked) recipe.likes--;
    } else {
      if (previousReaction == ReactionState.liked) recipe.likes--;
      recipe.userReaction = newReaction;
      if (newReaction == ReactionState.liked) recipe.likes++;
    }
    notifyListeners();
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

  Future<void> addFavorites() async {
    for (var recipeId in _selectedAiRecipeIds) {
      await _apiClient.post('/api/recipes/$recipeId/favorite');
    }
    toggleAiSelectionMode();
    await fetchRecipes();
  }

  Future<void> addFavoritesByIds(List<int> recipeIds) async {
    for (var recipeId in recipeIds) {
      await _apiClient.post('/api/recipes/$recipeId/favorite');
    }
    await fetchRecipes();
  }

  Future<void> blockRecipes() async {
    for (var recipeId in _selectedAiRecipeIds) {
      await _apiClient.post('/api/recipes/ai-recommend/$recipeId/hide');
    }
    toggleAiSelectionMode();
    await fetchRecipes();
  }

  Future<void> deleteCustomRecipes() async {
    for (var recipeId in _selectedCustomRecipeIds) {
      await _apiClient.delete('/api/recipes/my/$recipeId');
    }
    toggleCustomSelectionMode();
    await fetchRecipes();
  }

  Future<bool> addCustomRecipe(Map<String, dynamic> recipeData) async {
    final response = await _apiClient.post('/api/recipes', body: recipeData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      await fetchRecipes();
      return true;
    }
    return false;
  }
}

