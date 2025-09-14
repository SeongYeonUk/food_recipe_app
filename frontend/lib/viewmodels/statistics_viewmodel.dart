// lib/viewmodels/statistics_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/statistics_model.dart';
import '../models/recipe_model.dart';
import './recipe_viewmodel.dart';

enum Period { overall, weekly, monthly }

class StatisticsViewModel with ChangeNotifier {
  RecipeViewModel? _recipeViewModel;

  bool _isLoading = false;
  bool _isIngredientPeriodSelectorVisible = false;
  bool _isRecipePeriodSelectorVisible = false;
  bool _isRecipeSelectionMode = false;
  final Set<int> _selectedRecipeIds = {}; // [수정] Set<String> -> Set<int>

  List<Recipe> _popularRecipes = [];
  List<PopularIngredient> _popularIngredients = [];

  bool get isLoading => _isLoading;
  bool get isIngredientPeriodSelectorVisible => _isIngredientPeriodSelectorVisible;
  bool get isRecipePeriodSelectorVisible => _isRecipePeriodSelectorVisible;
  bool get isRecipeSelectionMode => _isRecipeSelectionMode;
  Set<int> get selectedRecipeIds => _selectedRecipeIds; // [수정] Set<String> -> Set<int>
  List<PopularIngredient> get popularIngredients => _popularIngredients;
  List<Recipe> get popularRecipes => _popularRecipes;

  StatisticsViewModel() {
    _loadInitialIngredients();
  }

  void setRecipeViewModel(RecipeViewModel recipeViewModel) {
    _recipeViewModel = recipeViewModel;
  }

  void updateAllRecipes(List<Recipe> allRecipes) {
    final sortedRecipes = List<Recipe>.from(allRecipes);
    sortedRecipes.sort((a, b) => b.likes.compareTo(a.likes));
    _popularRecipes = sortedRecipes;
  }

  Future<void> _loadInitialIngredients() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    _popularIngredients = [
      PopularIngredient(name: '계란', count: 24, coupangUrl: 'https://www.coupang.com/np/search?q=계란'),
      PopularIngredient(name: '양파', count: 19, coupangUrl: 'https://www.coupang.com/np/search?q=양파'),
      PopularIngredient(name: '대파', count: 17, coupangUrl: 'https://www.coupang.com/np/search?q=대파'),
    ];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStatisticsByPeriod({Period period = Period.overall}) async {
    print('$period 데이터를 서버에 요청합니다.');
    _loadInitialIngredients();
  }

  void toggleIngredientPeriodSelector() {
    _isIngredientPeriodSelectorVisible = !_isIngredientPeriodSelectorVisible;
    notifyListeners();
  }

  void toggleRecipePeriodSelector() {
    _isRecipePeriodSelectorVisible = !_isRecipePeriodSelectorVisible;
    _isRecipeSelectionMode = _isRecipePeriodSelectorVisible;
    if(!_isRecipeSelectionMode) _selectedRecipeIds.clear();
    notifyListeners();
  }

  // [수정] String recipeId -> int recipeId
  void selectRecipe(int recipeId) {
    if (_selectedRecipeIds.contains(recipeId)) {
      _selectedRecipeIds.remove(recipeId);
    } else {
      _selectedRecipeIds.add(recipeId);
    }
    notifyListeners();
  }

  Future<void> addFavorites() async {
    if (_recipeViewModel == null) return;
    // [수정] List<String> -> List<int>
    await _recipeViewModel!.addFavoritesByIds(_selectedRecipeIds.toList());
    toggleRecipePeriodSelector();
  }
}
