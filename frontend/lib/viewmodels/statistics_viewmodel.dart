// lib/viewmodels/statistics_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/statistics_model.dart';
import '../models/recipe_model.dart';
import './recipe_viewmodel.dart'; // RecipeViewModel을 import

enum Period { overall, weekly, monthly }

class StatisticsViewModel with ChangeNotifier {
  RecipeViewModel? _recipeViewModel; // RecipeViewModel 인스턴스를 저장할 변수

  bool _isLoading = false;
  bool _isIngredientPeriodSelectorVisible = false;
  bool _isRecipePeriodSelectorVisible = false;
  bool _isRecipeSelectionMode = false;
  final Set<String> _selectedRecipeIds = {};

  List<Recipe> _popularRecipes = [];
  List<PopularIngredient> _popularIngredients = [];

  bool get isLoading => _isLoading;
  bool get isIngredientPeriodSelectorVisible => _isIngredientPeriodSelectorVisible;
  bool get isRecipePeriodSelectorVisible => _isRecipePeriodSelectorVisible;
  bool get isRecipeSelectionMode => _isRecipeSelectionMode;
  Set<String> get selectedRecipeIds => _selectedRecipeIds;
  List<PopularIngredient> get popularIngredients => _popularIngredients;
  List<Recipe> get popularRecipes => _popularRecipes;

  StatisticsViewModel() {
    _loadInitialIngredients();
  }

  // [핵심 추가] RecipeViewModel 인스턴스를 받아 저장하는 메소드
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

  void selectRecipe(String recipeId) {
    if (_selectedRecipeIds.contains(recipeId)) {
      _selectedRecipeIds.remove(recipeId);
    } else {
      _selectedRecipeIds.add(recipeId);
    }
    notifyListeners();
  }

  // [핵심 수정] RecipeViewModel의 메소드를 호출하도록 변경
  Future<void> addFavorites() async {
    if (_recipeViewModel == null) {
      print('RecipeViewModel이 연결되지 않았습니다.');
      return;
    }
    // RecipeViewModel의 새로운 메소드를 호출하여 선택된 ID 목록을 전달
    await _recipeViewModel!.addFavoritesByIds(_selectedRecipeIds.toList());
    toggleRecipePeriodSelector();
  }
}

