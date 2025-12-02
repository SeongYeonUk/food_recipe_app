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
  bool get isIngredientPeriodSelectorVisible =>
      _isIngredientPeriodSelectorVisible;
  bool get isRecipePeriodSelectorVisible => _isRecipePeriodSelectorVisible;

  List<PopularRecipe> get mostViewedRecipes {
    var sortedList = List<PopularRecipe>.from(_popularRecipes);
    sortedList.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sortedList;
  }

  List<PopularRecipe> get todayShowcaseRecipes {
    var filtered = _popularRecipes.where((r) => r.isCustom).toList();
    filtered.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) {
        return b.id.compareTo(a.id);
      }
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return filtered;
  }

  StatisticsViewModel() {
    fetchAllStatistics();
  }

  void incrementRecipeView(PopularRecipe recipe) {
    // TODO: 백엔드 API가 준비되면, 여기에 조회수 증가 API를 호출하는 코드를 추가해야 합니다.
    final targetRecipe = _popularRecipes.firstWhere(
      (r) => r.id == recipe.id,
      orElse: () => recipe,
    );
    targetRecipe.viewCount++;
    notifyListeners();
  }

  Future<void> fetchAllStatistics() async {
    _isLoading = true;
    notifyListeners();
    try {
      final responses = await Future.wait([
        _apiClient.get('/api/statistics/ingredients?period=overall'),
        _apiClient.get('/api/statistics/recipes?period=overall&type=user_only'),
      ]);

      print("====== 서버로부터 받은 레시피 순위 (RAW JSON) ======");
      print(utf8.decode(responses[1].bodyBytes));
      print("==============================================");

      if (responses[0].statusCode == 200) {
        final List<dynamic> ingredientData = jsonDecode(
          utf8.decode(responses[0].bodyBytes),
        );
        _popularIngredients = ingredientData
            .map((data) => PopularIngredient.fromJson(data))
            .toList();
      } else {
        throw Exception('인기 재료 로딩 실패');
      }
      if (responses[1].statusCode == 200) {
        final List<dynamic> recipeData = jsonDecode(
          utf8.decode(responses[1].bodyBytes),
        );
        _popularRecipes = recipeData
            .map((data) => PopularRecipe.fromJson(data))
            .toList();
      } else {
        throw Exception('인기 레시피 로딩 실패');
      }
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
      final response = await _apiClient.get(
        '/api/statistics/ingredients?period=${_periodToString(period)}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _popularIngredients = responseData
            .map((data) => PopularIngredient.fromJson(data))
            .toList();
        _errorMessage = null;
      } else {
        throw Exception('인기 재료 로딩 실패');
      }
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
      final response = await _apiClient.get(
        '/api/statistics/recipes?period=${_periodToString(period)}&type=user_only',
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _popularRecipes = responseData
            .map((data) => PopularRecipe.fromJson(data))
            .toList();
        _errorMessage = null;
      } else {
        throw Exception('인기 레시피 로딩 실패');
      }
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

  // 💡 좋아요 카운트 동기화 함수
  void updateRecipeLikeCount(int recipeId, int newLikeCount) {
    try {
      // 1. 해당 레시피가 popularRecipes 리스트에 있는 인덱스를 찾습니다.
      final index = popularRecipes.indexWhere((r) => r.id == recipeId);

      if (index != -1) {
        final oldRecipe = popularRecipes[index];

        // 2. copyWith를 호출하여 likeCount가 갱신된 새로운 객체를 생성합니다.
        // (PopularRecipe 모델에 copyWith 메서드가 추가되어 있어야 합니다.)
        final newRecipe = oldRecipe.copyWith(likeCount: newLikeCount);

        // 3. 리스트에서 기존 객체 대신 새로운 객체로 교체합니다.
        popularRecipes[index] = newRecipe;

        // 4. ⭐ notifyListeners()를 호출하여 화면 갱신을 요청합니다.
        notifyListeners();
      }
    } catch (e) {
      // 오류 처리
    }
  }
}
