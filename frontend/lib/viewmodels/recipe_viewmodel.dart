// lib/viewmodels/recipe_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class RecipeViewModel with ChangeNotifier {
  // --- 상태 변수 ---
  List<Recipe> _aiRecipes = [];
  List<Recipe> _customRecipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAiSelectionMode = false;
  bool _isCustomSelectionMode = false;
  final Set<String> _selectedAiRecipeIds = {};
  final Set<String> _selectedCustomRecipeIds = {};
  List<String> _userIngredients = [];

  // --- Getters (UI에서 데이터에 접근하는 통로) ---
  List<Recipe> get customRecipes => _customRecipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAiSelectionMode => _isAiSelectionMode;
  bool get isCustomSelectionMode => _isCustomSelectionMode;
  Set<String> get selectedAiRecipeIds => _selectedAiRecipeIds;
  Set<String> get selectedCustomRecipeIds => _selectedCustomRecipeIds;
  List<String> get userIngredients => _userIngredients;
  List<Recipe> get allAiRecipes => _aiRecipes; // 상세페이지를 위한 필터링 안된 원본 목록

  // 보유 재료 기반으로 AI 레시피를 필터링하는 Getter
  List<Recipe> get filteredAiRecipes {
    if (_userIngredients.isEmpty) return _aiRecipes;
    return _aiRecipes.where((recipe) {
      return recipe.ingredients.any((recipeIngredient) {
        final coreIngredient = recipeIngredient.split(' ')[0];
        return _userIngredients.contains(coreIngredient);
      });
    }).toList();
  }

  // --- 생성자 ---
  RecipeViewModel() {
    fetchRecipes();
  }

  // --- 메소드 ---

  // RefrigeratorViewModel로부터 사용자 재료 목록을 업데이트 받음
  void updateUserIngredients(List<String> newIngredients) {
    _userIngredients = newIngredients;
    notifyListeners();
  }

  // 임시(Mock) 레시피 데이터를 불러옴
  Future<void> fetchRecipes() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _aiRecipes = [
      Recipe(id: "ai-1", name: '돼지고기 김치찌개', ingredients: ['돼지고기', '김치', '두부'], instructions: ['돼지고기와 김치를 볶는다.', '물을 붓고 끓인다.', '두부와 대파를 넣고 마무리한다.'], likes: 128, isCustom: false, imageAssetPath: 'asset/img/recipe/kimchi_jjigae.jpg', cookingTime: '30분'),
      Recipe(id: "ai-2", name: '소고기 미역국', ingredients: ['소고기', '미역', '국간장'], instructions: ['소고기와 미역을 참기름에 볶는다.', '물을 넣고 끓인다.', '국간장으로 간을 맞춘다.'], likes: 256, isCustom: false, imageAssetPath: 'asset/img/recipe/miyeok_guk.jpg', cookingTime: '25분'),
      Recipe(id: "ai-3", name: '계란찜', ingredients: ['계란', '물', '새우젓'], instructions: ['계란과 물, 새우젓을 잘 섞는다.', '뚝배기에 넣고 약불에서 익힌다.'], likes: 95, isCustom: false, imageAssetPath: 'asset/img/recipe/gyeranjjim.jpg', cookingTime: '15분'),
    ];
    _customRecipes = [
      Recipe(id: "custom-101", name: '우리집 비밀 라면', ingredients: ['라면', '계란', '치즈', '대파'], instructions: ['물을 끓인다.', '면과 스프를 넣는다.', '마지막에 계란과 치즈, 대파를 넣는다.'], likes: 5, isCustom: true, imageAssetPath: 'asset/img/recipe/ramen.jpg', cookingTime: '10분'),
    ];
    _isLoading = false;
    notifyListeners();
  }

  // 좋아요/싫어요 상태 변경
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

  // 선택 모드 토글
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

  // 레시피 선택/해제
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

  // '레시피 추천' 화면의 즐겨찾기 추가 기능 (복사 방식)
  Future<void> addFavorites() async {
    final List<Recipe> recipesToAdd = [];
    for (var id in _selectedAiRecipeIds) {
      final originalRecipe = _aiRecipes.firstWhere((r) => r.id == id);

      // [수정] '이름'으로 중복 확인
      bool isAlreadyCustom = _customRecipes.any((recipe) => recipe.name == originalRecipe.name);
      if (isAlreadyCustom) continue;

      recipesToAdd.add(Recipe(id: "custom-${DateTime.now().millisecondsSinceEpoch}-${originalRecipe.id}", name: originalRecipe.name, ingredients: originalRecipe.ingredients, instructions: originalRecipe.instructions, likes: originalRecipe.likes, isCustom: true, imageAssetPath: originalRecipe.imageAssetPath, cookingTime: originalRecipe.cookingTime));
    }
    _customRecipes.insertAll(0, recipesToAdd);

    // [수정] 원본을 삭제하는 코드를 제거하여 '복사'처럼 동작하게 함
    // _aiRecipes.removeWhere((r) => _selectedAiRecipeIds.contains(r.id));

    toggleAiSelectionMode();
  }

  // '통계' 화면 연동을 위한 즐겨찾기 추가 기능 (중복 방지)
  Future<void> addFavoritesByIds(List<String> recipeIds) async {
    final List<Recipe> recipesToAdd = [];
    final allRecipes = [..._aiRecipes, ..._customRecipes];

    for (var id in recipeIds) {
      final originalRecipe = allRecipes.firstWhere((r) => r.id == id);

      // [수정] '이름'으로 중복 확인
      bool isAlreadyCustom = _customRecipes.any((recipe) => recipe.name == originalRecipe.name);
      if (isAlreadyCustom) continue;

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
    _customRecipes.insertAll(0, recipesToAdd);
    notifyListeners();
  }

  // '추천 안함' 기능 (화면에서 임시로 숨김)
  Future<void> blockRecipes() async {
    _aiRecipes.removeWhere((r) => _selectedAiRecipeIds.contains(r.id));
    toggleAiSelectionMode();
  }

  // '나만의 레시피' 삭제 기능
  Future<void> deleteCustomRecipes() async {
    _customRecipes.removeWhere((r) => _selectedCustomRecipeIds.contains(r.id));
    toggleCustomSelectionMode();
  }

  // 새로운 '나만의 레시피' 생성 기능 (중복 방지)
  Future<void> addCustomRecipe(Recipe newRecipe) async {
    bool isAlreadyCustom = _customRecipes.any((recipe) => recipe.name == newRecipe.name);
    if(isAlreadyCustom) {
      print('이미 같은 이름의 레시피가 존재합니다: ${newRecipe.name}');
      return;
    }
    _customRecipes.insert(0, newRecipe);
    notifyListeners();
  }
}
