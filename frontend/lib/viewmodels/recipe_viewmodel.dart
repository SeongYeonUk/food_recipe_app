// lib/viewmodels/recipe_viewmodel.dart (최종 ?�정�?

import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import './statistics_viewmodel.dart';
import '../models/recipe_model.dart'; // [?�정] Ingredient 모델???�해 import
import '../common/api_client.dart';
import '../models/ingredient_input_model.dart';
import 'package:collection/collection.dart';
import '../user/user_model.dart';
import '../models/ingredient_model.dart'; // [추�?] Ingredient 모델 import

class RecipeViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final UserModel _userModel = UserModel();
  List<Recipe> _allRecipes = [];
  List<Recipe> _recommendedRecipes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAiSelectionMode = false;
  bool _isMyRecipeSelectionMode = false;
  bool _isFavoriteSelectionMode = false;
  final Set<int> _selectedAiRecipeIds = {};
  final Set<int> _selectedMyRecipeIds = {};
  final Set<int> _selectedFavoriteRecipeIds = {};

  // [?�️?�정] List<String> -> List<Ingredient> ?�?�으�?변�?
  List<Ingredient> _userIngredients = [];
  List<String> _allergyNames = [];
  static const int maxAiRecommendations = 20;

  // --- Getters ---

  // [?�정] !r.isFavorite 조건??추�??�서, 즐겨찾기�??�동???�시?�는 ??목록?�서 ?�외?�니??
  List<Recipe> get myRecipes =>
      _allRecipes.where(_isMyCustomRecipe).toList();

  // [?�정] !r.isCustom 조건????��?�서, '?�만???�시????즐겨찾기 목록???�함?�도�??�니??
  List<Recipe> get favoriteRecipes =>
      _allRecipes.where((r) => r.isFavorite).toList();

  List<Recipe> get allRecipes => _allRecipes;
  List<Recipe> get allAiRecipes =>
      _allRecipes.where((r) => !r.isCustom && _passesAllergyFilter(r)).toList();
  List<Recipe> get recommendedRecipes => _recommendedRecipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAiSelectionMode => _isAiSelectionMode;
  bool get isMyRecipeSelectionMode => _isMyRecipeSelectionMode;
  bool get isFavoriteSelectionMode => _isFavoriteSelectionMode;
  Set<int> get selectedAiRecipeIds => _selectedAiRecipeIds;
  Set<int> get selectedMyRecipeIds => _selectedMyRecipeIds;
  Set<int> get selectedFavoriteRecipeIds => _selectedFavoriteRecipeIds;

  // [?�️?�정] List<String> -> List<Ingredient> ?�?�으�?변�?
  List<Ingredient> get userIngredients => _userIngredients;

  List<Recipe> get customRecipes {
    return _allRecipes.where((r) => r.isCustom || r.isFavorite).toList();
  }

  // [?�️?�정] getter가 ?�닌 ?�반 변?�로 변�?(?�계??로직?�서 값을 ?�당?�야 ?��?�?
  List<Recipe> _filteredAiRecipes = [];
  // ---

  // lib/viewmodels/recipe_viewmodel.dart

  // ?�버?�서 ?�려주는 추천 ?�시?��? 그�?�??�용?�니??최�? 개수???�버?�서 ?�한).
  // 비어?�을 ?�만 기존 allAiRecipes�??�백.
  List<Recipe> get filteredAiRecipes {
    List<Recipe> base;
    if (_filteredAiRecipes.isNotEmpty) {
      base = _filteredAiRecipes;
    } else if (_recommendedRecipes.isNotEmpty) {
      base = _recommendedRecipes;
    } else {
      base = allAiRecipes;
    }
    return base.length > maxAiRecommendations
        ? base.sublist(0, maxAiRecommendations)
        : base;
  }
  List<Recipe> _calculateFilteredAiRecipes() {
    // [?�️?�정] 기존 getter 로직??'계산 ?�수'�?변�?
    if (_userIngredients.isEmpty) {
      return allAiRecipes;
    }

    print("--- 최종 ?�터�?검�??�작 ---");
    // [?�️?�정] List<String> -> List<Ingredient> ?��?�??�름�?추출
    print("???�장�??�료: ${_userIngredients.map((e) => e.name).toList()}");

    final List<Recipe> result = [];
    // 1. 모든 AI ?�시?��? ?�나???�인
    for (final recipe in allAiRecipes) {
      bool isMatchFound = false;
      // 2. ?�시?�의 모든 ?�료�??�나???�인
      for (final recipeIngredient in recipe.ingredients) {
        // 3. ???�장고의 모든 ?�료�??�나???�인
        // [?�️?�정] List<String> -> List<Ingredient> ?��?�?ing.name ?�용
        for (final userIngredient in _userIngredients) {
          // 비교 ?? ?�쪽??모든 공백???�거?�서 ?�확?��? ?�입?�다.
          final cleanRecipeIngredient = recipeIngredient.trim();
          final cleanUserIngredient = userIngredient.name
              .trim(); // [?�️?�정] ing.name ?�용

          // ?��?��?�� [?�버�?로그] ?�떤 ?�어?�이 비교?�는지 ?�으�??�인?�니?? ?��?��?��
          print(
            "  [비교] ?�시???�료: '${cleanRecipeIngredient}' (길이: ${cleanRecipeIngredient.length}) | ???�료: '${cleanUserIngredient}' (길이: ${cleanUserIngredient.length})",
          );

          // [?�️?�정] ?�시???�료명에 ???�료명이 ?�함?�어 ?�는지 ?�인
          if (cleanRecipeIngredient.contains(cleanUserIngredient)) {
            print("  ??매치 ?�공!");
            isMatchFound = true;
            break; // ?�료 ?�나?�도 찾았?�면 ?�음 ?�시?�로 ?�어�?
          }
        }
        if (isMatchFound) {
          break; // ?�료 ?�나?�도 찾았?�면 ?�음 ?�시?�로 ?�어�?
        }
      }

      if (isMatchFound) {
        result.add(recipe);
      }
    }
    print("--- 최종 ?�터�?검�?종료: ${result.length}�??�시??찾음 ---");
    return result;
  }

  RecipeViewModel() {}

  Future<void> loadInitialData() {
    return fetchRecipes();
  }

  // [?�️?�정] ProxyProvider가 ?�출??'공개' ?�데?�트 ?�수
  // (List<String>???�닌 List<Ingredient>�?받도�??�정)
  void updateUserIngredients(List<Ingredient> newIngredients) {
    // ?�료 목록???�제�?변경되?�는지 ?�인 (?�순 비교)
    if (_userIngredients != newIngredients) {
      _userIngredients = newIngredients;
      _recalculateAiRecipes(); // ?�료가 ?�데?�트?�었?�니 AI 추천 ?�계??
    }
  }

  Future<void> fetchRecipes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _refreshAllergyNames();
      final response = await _apiClient.get('/api/recipes');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        // [?�️?�정] API ?�답 ?�이?��? _allRecipes???�??
        _allRecipes = responseData
            .map((data) => Recipe.fromJson(data))
            .toList();

        // [?�️?�정] ?�시??로딩 직후, ?�재 ?�료�??�계???�도
        _recalculateAiRecipes();
      } else {
        throw Exception('?�시??목록 로딩 ?�패 (코드: ${response.statusCode})');
      }
    } catch (e) {
      _errorMessage = '?�이??로딩 �??�류 발생: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ?�버 추천 ?�시???�용???�장�?기반)�?가?�옵?�다.
  Future<void> fetchRecommendedRecipes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final bool allergiesUpdated = await _refreshAllergyNames();
      final response = await _apiClient.get('/api/recipes/recommendations');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _recommendedRecipes =
            responseData.map((data) => Recipe.fromJson(data)).toList();
        _recommendedRecipes = _applyAllergyFilter(_recommendedRecipes);
        if (allergiesUpdated) {
          _recalculateAiRecipes();
        }
      } else {
        throw Exception('?? ??? ???? ?? (??: ${response.statusCode})');
      }
    } catch (e) {
      _errorMessage = '?? ??? ???? ? ??: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search recipes on server by selected ingredient names
  Future<void> searchByIngredientNames(List<String> names) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/recipes/search-by-ingredients', body: {'names': names});
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _allRecipes = responseData.map((data) => Recipe.fromJson(data)).toList();
      } else {
        throw Exception('?�시??검???�패 (${response.statusCode})');
      }
    } catch (e) {
      _errorMessage = '?�시??검??�??�류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // [?�️?�정] AI 추천 ?�시?��? '?�계???�는 ?��? ?�수
  void _recalculateAiRecipes() {
    // 1. ?�료가 ?�거???�시???�본???�으�?계산 중�?
    if (_userIngredients.isEmpty || _allRecipes.isEmpty) {
      _filteredAiRecipes = allAiRecipes; // [?�️?�정] ?�료 ?�으�?AI ?�시??'?�체'�?보여�?
      notifyListeners(); // UI 갱신
      return;
    }

    // 2. [?�️?�정] 기존 getter 로직?�었??계산 ?�수�??�출
    final List<Recipe> recommendations = _calculateFilteredAiRecipesV2();

    // 3. 최종 결과�??�성???�?�하�?UI 갱신
    _filteredAiRecipes = recommendations;
    notifyListeners();
  }

  // Improved algorithm: score by matching ingredient count and cap the results
  List<Recipe> _calculateFilteredAiRecipesV2() {
    if (_userIngredients.isEmpty) {
      final base = allAiRecipes;
      return base.length > maxAiRecommendations
          ? base.sublist(0, maxAiRecommendations)
          : base;
    }

    final List<String> userNames = _userIngredients
        .map((e) => e.name.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<MapEntry<Recipe, int>> scored = [];
    for (final recipe in allAiRecipes) {
      int matches = 0;
      for (final recipeIngredient in recipe.ingredients) {
        final ri = recipeIngredient.trim();
        for (final un in userNames) {
          if (ri.contains(un)) {
            matches++;
            break;
          }
        }
      }
      if (matches > 0) {
        scored.add(MapEntry(recipe, matches));
      }
    }

    scored.sort((a, b) {
      final cmp = b.value.compareTo(a.value);
      if (cmp != 0) return cmp;
      return (b.key.likes).compareTo(a.key.likes);
    });

    final result = scored.map((e) => e.key).toList();
    return result.length > maxAiRecommendations
        ? result.sublist(0, maxAiRecommendations)
        : result;
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
        throw Exception('?�시???�보�?불러?�는 ???�패?�습?�다: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipe details: $e');
      throw Exception('?�시???�보�?불러?�는 ???�패?�습?�다.');
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

  // [?�정] AI?� '?�만???�시?? 모두 처리?�는 ?�합 즐겨찾기 추�? ?�수
  Future<void> addSelectedToFavorites() async {
    // 1. ?�재 ?�성?�된 ?�택 모드???�라 ?�떤 ID 목록???�용?��? 결정?�니??
    final Set<int> idsToAdd = _isAiSelectionMode
        ? _selectedAiRecipeIds
        : _selectedMyRecipeIds;

    if (idsToAdd.isEmpty) return;

    try {
      await _apiClient.post(
        '/api/recipes/favorites',
        body: {'recipeIds': idsToAdd.toList()},
      );
      // 2. ?�공 ?? UI�?즉시 ?�데?�트?�기 ?�해 ?�택???�시?�들??isFavorite ?�태�?true�?변�?
      for (var recipeId in idsToAdd) {
        final recipe = _allRecipes.firstWhereOrNull((r) => r.id == recipeId);
        if (recipe != null) {
          recipe.isFavorite = true;
        }
      }
    } catch (e) {
      print('즐겨찾기 추�? ?�패: $e');
      // ?�요?�다�??�기???�러 발생 ???�용?�에�??�려주는 로직 추�?
    } finally {
      // 3. ?�떤 모드?�?? ?�업???�나�??�당 ?�택 모드�??�제?�니??
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

  // lib/viewmodels/recipe_viewmodel.dart

  // ?��?��?�� ??deleteFavorites ?�수�??�래 코드�?교체?�주?�요. ?��?��?��
  Future<void> deleteFavorites() async {
    if (_selectedFavoriteRecipeIds.isEmpty) return;

    // 1. ??��??ID 목록??미리 복사?�둡?�다. (가??중요!)
    final idsToDelete = _selectedFavoriteRecipeIds.toList();

    // 2. ?�버??먼�? ??�� ?�청??보냅?�다.
    try {
      await _apiClient.delete(
        '/api/recipes/favorites',
        body: {'recipeIds': idsToDelete},
      );

      // 3. ?�버 ?�청???�공?�면, ???�면???�태�??�데?�트?�니??
      for (var recipeId in idsToDelete) {
        final recipe = _allRecipes.firstWhereOrNull((r) => r.id == recipeId);
        if (recipe != null) {
          recipe.isFavorite = false;
        }
      }
    } catch (e) {
      print('즐겨찾기 ??�� ?�패: $e');
      // ?�러가 발생?�더?�도 ?�용??경험???�해 ?�택 모드???�제?�주??것이 좋습?�다.
    } finally {
      // 4. ?�공?�든 ?�패?�든, 마�?막으�??�택 모드�??�제?�니??
      // (?�때 _selectedFavoriteRecipeIds 목록??초기?�됩?�다)
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

  Future<bool> _refreshAllergyNames() async {
    try {
      final response = await _apiClient.get('/api/allergies');
      if (response.statusCode != 200) return false;
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<String> normalized = data
          .map((entry) => _normalizeText(entry['name']?.toString() ?? ''))
          .where((name) => name.isNotEmpty)
          .toList();
      final hasChanged =
          !const ListEquality<String>().equals(_allergyNames, normalized);
      _allergyNames = normalized;
      _filteredAiRecipes = _applyAllergyFilter(_filteredAiRecipes);
      _recommendedRecipes = _applyAllergyFilter(_recommendedRecipes);
      return hasChanged;
    } catch (_) {
      return false;
    }
  }

  List<Recipe> _applyAllergyFilter(List<Recipe> recipes) {
    if (_allergyNames.isEmpty) return recipes;
    return recipes.where(_passesAllergyFilter).toList();
  }

  bool _passesAllergyFilter(Recipe recipe) {
    if (_allergyNames.isEmpty) return true;
    final Iterable<String> candidates = <String>[
      recipe.name,
      recipe.description,
      ...recipe.ingredients,
    ];
    for (final raw in candidates) {
      final normalized = _normalizeText(raw);
      if (normalized.isEmpty) continue;
      for (final allergy in _allergyNames) {
        if (normalized.contains(allergy)) {
          return false;
        }
      }
    }
    return true;
  }

  String _normalizeText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _isMyCustomRecipe(Recipe recipe) {
    if (!recipe.isCustom || recipe.isFavorite) return false;
    final nickname = _userModel.nickname?.trim();
    if (nickname == null || nickname.isEmpty) return true;
    return recipe.authorNickname.trim() == nickname;
  }
}

