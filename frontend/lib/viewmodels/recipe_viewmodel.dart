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
  bool _isMyRecipeSelectionMode = false;
  bool _isFavoriteSelectionMode = false;
  final Set<int> _selectedAiRecipeIds = {};
  final Set<int> _selectedMyRecipeIds = {};
  final Set<int> _selectedFavoriteRecipeIds = {};
  List<String> _userIngredients = [];

  List<Recipe> get myRecipes => _allRecipes.where((r) => r.isCustom).toList();
  List<Recipe> get favoriteRecipes => _allRecipes.where((r) => !r.isCustom && r.isFavorite).toList();
  List<Recipe> get allRecipes => _allRecipes;
  List<Recipe> get allAiRecipes => _allRecipes.where((r) => !r.isCustom).toList();
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

  Future<Recipe> fetchRecipeById(int recipeId) async {
    try {
      final response = await _apiClient.get('/api/recipes/$recipeId');

      // [수정] 기존 fetchRecipes와 동일한 방식으로 http 응답을 처리합니다.
      if (response.statusCode == 200) {
        // 1. bodyBytes를 utf8로 디코딩 (한글 깨짐 방지)
        final String responseBody = utf8.decode(response.bodyBytes);
        // 2. 디코딩된 문자열을 JSON Map으로 변환
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);
        // 3. JSON Map으로 Recipe 객체 생성
        return Recipe.fromJson(jsonData);
      } else {
        // 서버가 200 OK가 아닌 다른 상태 코드를 반환한 경우
        throw Exception('레시피 정보를 불러오는 데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      // 오류 발생 시 처리
      print('Error fetching recipe details: $e');
      throw Exception('레시피 정보를 불러오는 데 실패했습니다.');
    }
  }

  Future<void> updateReaction(int recipeId, ReactionState newReaction) async {
    final recipe = _allRecipes.firstWhere((r) => r.id == recipeId);
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
    notifyListeners();
    try {
      await _apiClient.post('/api/recipes/$recipeId/reaction', body: {'reaction': reactionString});
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
    if (_selectedAiRecipeIds.contains(recipeId)) _selectedAiRecipeIds.remove(recipeId);
    else _selectedAiRecipeIds.add(recipeId);
    notifyListeners();
  }

  void selectMyRecipe(int recipeId) {
    if (_selectedMyRecipeIds.contains(recipeId)) _selectedMyRecipeIds.remove(recipeId);
    else _selectedMyRecipeIds.add(recipeId);
    notifyListeners();
  }

  void selectFavoriteRecipe(int recipeId) {
    if (_selectedFavoriteRecipeIds.contains(recipeId)) _selectedFavoriteRecipeIds.remove(recipeId);
    else _selectedFavoriteRecipeIds.add(recipeId);
    notifyListeners();
  }

  Future<void> addFavorites() async {
    if (_selectedAiRecipeIds.isEmpty) return;
    try {
      await _apiClient.post(
        '/api/recipes/favorites',
        body: {'recipeIds': _selectedAiRecipeIds.toList()},
      );
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

  Future<void> deleteMyRecipes() async {
    if (_selectedMyRecipeIds.isEmpty) return;
    final idsToDelete = Set<int>.from(_selectedMyRecipeIds);
    _allRecipes.removeWhere((r) => idsToDelete.contains(r.id) && r.isCustom);
    toggleMyRecipeSelectionMode();
    try {
      await _apiClient.delete('/api/recipes/favorites', body: {'recipeIds': idsToDelete.toList()});
    } catch (e) { await fetchRecipes(); }
  }

  Future<void> deleteFavorites() async {
    if (_selectedFavoriteRecipeIds.isEmpty) return;
    for (var recipeId in _selectedFavoriteRecipeIds) {
      _allRecipes.firstWhere((r) => r.id == recipeId).isFavorite = false;
    }
    toggleFavoriteSelectionMode();
    try {
      await _apiClient.delete('/api/recipes/favorites', body: {'recipeIds': _selectedFavoriteRecipeIds.toList()});
    } catch (e) { await fetchRecipes(); }
  }

  Future<void> blockRecipes() async {
    if (_selectedAiRecipeIds.isEmpty) return;
    final idsToBlock = Set<int>.from(_selectedAiRecipeIds);
    toggleAiSelectionMode();
    try {
      await _apiClient.post('/api/recipes/ai-recommend/hide-bulk', body: {'recipeIds': idsToBlock.toList()});
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
    };
    try {
      await _apiClient.post('/api/recipes', body: recipeData);
      await fetchRecipes();
      return true;
    } catch(e) {
      return false;
    }
  }
}