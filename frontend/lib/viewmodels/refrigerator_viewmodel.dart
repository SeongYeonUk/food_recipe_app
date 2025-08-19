// lib/viewmodels/refrigerator_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../common/api_client.dart';

class RefrigeratorViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  int _selectedIndex = 1;
  bool _isLoading = false;
  String? _errorMessage;

  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final List<Refrigerator> _refrigerators = [
    Refrigerator(id: 3, name: '냉동실', currentImage: 'asset/img/Refrigerator/냉동실1.png', availableImages: ['asset/img/Refrigerator/냉동실1.png', 'asset/img/Refrigerator/냉동실2.png', 'asset/img/Refrigerator/냉동실3.png']),
    Refrigerator(id: 1, name: '메인냉장고', currentImage: 'asset/img/Refrigerator/냉장고1.png', availableImages: ['asset/img/Refrigerator/냉장고1.png', 'asset/img/Refrigerator/냉장고2.png', 'asset/img/Refrigerator/냉장고3.png', 'asset/img/Refrigerator/냉장고4.png']),
    Refrigerator(id: 2, name: '김치냉장고', currentImage: 'asset/img/Refrigerator/김치냉장고1.png', availableImages: ['asset/img/Refrigerator/김치냉장고1.png', 'asset/img/Refrigerator/김치냉장고2.png']),
  ];
  List<Refrigerator> get refrigerators => _refrigerators;

  List<Ingredient> _ingredients = [];

  List<Ingredient> get filteredIngredients {
    _ingredients.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return _ingredients;
  }

  void changeRefrigeratorImage(int index, String newImage) {
    _refrigerators[index].currentImage = newImage;
    notifyListeners();
  }

  Future<void> fetchIngredients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final refrigeratorId = _refrigerators[_selectedIndex].id;
      final response = await _apiClient.get('/api/refrigerators/$refrigeratorId/items');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _ingredients = responseData.map((data) =>
            Ingredient.fromJson(data, _refrigerators[_selectedIndex].name)).toList();
      } else {
        _errorMessage = '데이터를 불러오는데 실패했습니다. (코드: ${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = '오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectRefrigerator(int index) async {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    await fetchIngredients();
  }

  Future<bool> addIngredient(Ingredient newIngredient) async {
    try {
      final refrigeratorId = _refrigerators.firstWhere((r) => r.name == newIngredient.refrigeratorType).id;
      final response = await _apiClient.post(
        '/api/refrigerators/$refrigeratorId/items',
        body: newIngredient.toJson(),
      );

      if (response.statusCode == 201) {
        await fetchIngredients();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateIngredient(Ingredient ingredientToUpdate) async {
    try {
      final refrigeratorId = _refrigerators.firstWhere((r) => r.name == ingredientToUpdate.refrigeratorType).id;
      final response = await _apiClient.put(
        '/api/refrigerators/$refrigeratorId/items/${ingredientToUpdate.id}',
        body: ingredientToUpdate.toJson(),
      );

      if (response.statusCode == 200) {
        await fetchIngredients();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteIngredient(int id) async {
    try {
      final refrigeratorId = _refrigerators[_selectedIndex].id;
      final response = await _apiClient.delete('/api/refrigerators/$refrigeratorId/items/$id');

      if (response.statusCode == 200) {
        _ingredients.removeWhere((ing) => ing.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}



