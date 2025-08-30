// lib/viewmodels/recipe_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class RecipeViewModel with ChangeNotifier {
  List<Recipe> _aiRecipes = [];
  List<Recipe> _customRecipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAiSelectionMode = false;
  bool _isCustomSelectionMode = false;
  final Set<String> _selectedAiRecipeIds = {};
  final Set<String> _selectedCustomRecipeIds = {};
  List<String> _userIngredients = [];

  List<Recipe> get customRecipes => _customRecipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAiSelectionMode => _isAiSelectionMode;
  bool get isCustomSelectionMode => _isCustomSelectionMode;
  Set<String> get selectedAiRecipeIds => _selectedAiRecipeIds;
  Set<String> get selectedCustomRecipeIds => _selectedCustomRecipeIds;
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
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _aiRecipes = [
      Recipe(
        id: "ai-1", name: '돼지고기 김치찌개',
        ingredients: ['돼지고기 300g', '김치 1/4포기', '두부 1모', '대파 반 줌'],
        instructions: ['돼지고기와 김치를 볶는다.', '물을 넣고 끓인다.', '두부와 대파를 넣고 마무리한다.'],
        likes: 128,
        isCustom: false,
        imageAssetPath: 'asset/img/recipe/kimchi_jjigae.jpg',
        cookingTime: '30분',
      ),
      Recipe(
        id: "ai-2", name: '소고기 미역국',
        ingredients: ['소고기 150g', '미역 20g', '국간장 2큰술'],
        instructions: ['소고기와 미역을 참기름에 볶는다.', '물을 넣고 끓인다.', '국간장으로 간을 맞춘다.'],
        likes: 256,
        isCustom: false,
        imageAssetPath: 'asset/img/recipe/miyeok_guk.jpg',
        cookingTime: '25분',
      ),
    ];
    _customRecipes = [
      Recipe(
        id: "custom-101", name: '우리집 비밀 라면',
        ingredients: ['라면 1개', '계란 1개', '치즈 1장', '대파 약간'],
        instructions: ['물을 끓인다.', '면과 스프를 넣는다.', '마지막에 계란과 치즈, 대파를 넣는다.'],
        likes: 5,
        isCustom: true,
        imageAssetPath: 'asset/img/recipe/ramen.jpg',
        cookingTime: '10분',
      ),
    ];
    _isLoading = false;
    notifyListeners();
  }

  void updateReaction(String recipeId, ReactionState newReaction) {
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

  void selectAiRecipe(String recipeId) {
    if (_selectedAiRecipeIds.contains(recipeId)) _selectedAiRecipeIds.remove(recipeId);
    else _selectedAiRecipeIds.add(recipeId);
    notifyListeners();
  }

  void selectCustomRecipe(String recipeId) {
    if (_selectedCustomRecipeIds.contains(recipeId)) _selectedCustomRecipeIds.remove(recipeId);
    else _selectedCustomRecipeIds.add(recipeId);
    notifyListeners();
  }

  Future<void> addFavorites() async {
    final List<Recipe> recipesToAdd = [];
    for (var id in _selectedAiRecipeIds) {
      final originalRecipe = _aiRecipes.firstWhere((r) => r.id == id);
      recipesToAdd.add(Recipe(
        id: "custom-${DateTime.now().millisecondsSinceEpoch}-${originalRecipe.id}",
        name: originalRecipe.name,
        ingredients: originalRecipe.ingredients,
        instructions: originalRecipe.instructions,
        likes: originalRecipe.likes,
        isCustom: true,
        imageAssetPath: originalRecipe.imageAssetPath,
        cookingTime: originalRecipe.cookingTime,
      ));
    }
    _customRecipes.addAll(recipesToAdd);
    _aiRecipes.removeWhere((r) => _selectedAiRecipeIds.contains(r.id));
    toggleAiSelectionMode();
  }

  Future<void> blockRecipes() async {
    _aiRecipes.removeWhere((r) => _selectedAiRecipeIds.contains(r.id));
    toggleAiSelectionMode();
  }

  Future<void> deleteCustomRecipes() async {
    _customRecipes.removeWhere((r) => _selectedCustomRecipeIds.contains(r.id));
    toggleCustomSelectionMode();
  }

  Future<void> addCustomRecipe(Recipe newRecipe) async {
    _customRecipes.insert(0, newRecipe);
    notifyListeners();
  }
}
