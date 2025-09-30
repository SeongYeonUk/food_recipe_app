// lib/viewmodels/statistics_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/statistics_model.dart';
import '../common/api_client.dart';

enum Period { overall, weekly, monthly }

class StatisticsViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;
  List<PopularIngredient> _popularIngredients = [];
  List<PopularRecipe> _popularRecipes = [];
  bool _isIngredientPeriodSelectorVisible = false;
  bool _isRecipePeriodSelectorVisible = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PopularIngredient> get popularIngredients => _popularIngredients;
  List<PopularRecipe> get popularRecipes => _popularRecipes;
  bool get isIngredientPeriodSelectorVisible => _isIngredientPeriodSelectorVisible;
  bool get isRecipePeriodSelectorVisible => _isRecipePeriodSelectorVisible;

  List<PopularRecipe> get mostViewedRecipes {
    var sortedList = List<PopularRecipe>.from(_popularRecipes);
    sortedList.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return sortedList;
  }

  List<PopularRecipe> get todayShowcaseRecipes => mostViewedRecipes;

  StatisticsViewModel() {
    fetchAllStatistics();
  }

  void incrementRecipeView(PopularRecipe recipe) {
    // TODO: 백엔드 API가 준비되면, 여기에 조회수 증가 API를 호출하는 코드를 추가해야 합니다.
    final targetRecipe = _popularRecipes.firstWhere((r) => r.id == recipe.id, orElse: () => recipe);
    targetRecipe.viewCount++;
    notifyListeners();
  }

  Future<void> fetchAllStatistics() async {
    _isLoading = true;
    notifyListeners();
    try {
      final responses = await Future.wait([
        _apiClient.get('/api/statistics/ingredients?period=overall'),
        _apiClient.get('/api/statistics/recipes?period=overall'),
      ]);
      if (responses[0].statusCode == 200) {
        final List<dynamic> ingredientData = jsonDecode(utf8.decode(responses[0].bodyBytes));
        _popularIngredients = ingredientData.map((data) => PopularIngredient.fromJson(data)).toList();
      } else { throw Exception('인기 재료 로딩 실패'); }
      if (responses[1].statusCode == 200) {
        final List<dynamic> recipeData = jsonDecode(utf8.decode(responses[1].bodyBytes));
        _popularRecipes = recipeData.map((data) => PopularRecipe.fromJson(data)).toList();
      } else { throw Exception('인기 레시피 로딩 실패'); }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '데이터 로딩 중 오류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPopularIngredients({required Period period}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/statistics/ingredients?period=${_periodToString(period)}');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _popularIngredients = responseData.map((data) => PopularIngredient.fromJson(data)).toList();
        _errorMessage = null;
      } else { throw Exception('인기 재료 로딩 실패'); }
    } catch (e) {
      _errorMessage = '데이터 로딩 중 오류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPopularRecipes({required Period period}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/statistics/recipes?period=${_periodToString(period)}');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _popularRecipes = responseData.map((data) => PopularRecipe.fromJson(data)).toList();
        _errorMessage = null;
      } else { throw Exception('인기 레시피 로딩 실패'); }
    } catch (e) {
      _errorMessage = '데이터 로딩 중 오류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _periodToString(Period period) {
    return period.toString().split('.').last;
  }

  void toggleIngredientPeriodSelector() {
    _isIngredientPeriodSelectorVisible = !_isIngredientPeriodSelectorVisible;
    notifyListeners();
  }

  void toggleRecipePeriodSelector() {
    _isRecipePeriodSelectorVisible = !_isRecipePeriodSelectorVisible;
    notifyListeners();
  }
}

