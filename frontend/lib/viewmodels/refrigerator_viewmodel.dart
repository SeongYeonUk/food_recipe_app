// lib/viewmodels/refrigerator_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../models/refrigerator_model.dart';
import '../common/api_client.dart';
import 'package:intl/intl.dart';

class RefrigeratorViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Refrigerator> _refrigerators = [];
  Map<int, List<Ingredient>> _ingredientMap = {};
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;

  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Refrigerator> get refrigerators => _refrigerators;

  List<Ingredient> get filteredIngredients {
    if (_refrigerators.isEmpty) return [];
    final selectedRefrigeratorId = _refrigerators[_selectedIndex].id;
    final ingredients = _ingredientMap[selectedRefrigeratorId] ?? [];
    ingredients.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return ingredients;
  }

  List<Ingredient> get allIngredientsForRecipe {
    return _ingredientMap.values.expand((list) => list).toList();
  }

  RefrigeratorViewModel() {
    fetchRefrigerators();
  }

  Future<void> fetchRefrigerators() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/refrigerators');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _refrigerators = responseData.map((data) => Refrigerator.fromJson(data)).toList();
        _selectedIndex = _refrigerators.indexWhere((r) => r.type == RefrigeratorType.main);
        if (_selectedIndex == -1 && _refrigerators.isNotEmpty) _selectedIndex = 0;
        if (_refrigerators.isNotEmpty) {
          await fetchAllIngredients();
        }
      } else {
        _errorMessage = '냉장고 목록 로딩 실패 (코드: ${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = '냉장고 목록 로딩 중 오류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllIngredients() async {
    _ingredientMap = {};
    for (var fridge in _refrigerators) {
      await fetchIngredientsForId(fridge.id);
    }
    notifyListeners();
  }

  Future<void> fetchIngredientsForId(int refrigeratorId) async {
    try {
      final response = await _apiClient.get('/api/refrigerators/$refrigeratorId/items');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _ingredientMap[refrigeratorId] = responseData.map((data) => Ingredient.fromJson(data, refrigeratorId)).toList();
      }
    } catch(e) {
      print('ID $refrigeratorId 식재료 로딩 실패');
      _ingredientMap[refrigeratorId] = [];
    }
  }

  Future<void> selectRefrigerator(int index) async {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void changeRefrigeratorImage(int index, String newImage) {
    if (index < _refrigerators.length) {
      _refrigerators[index].currentImage = newImage;
      notifyListeners();
    }
  }

  Future<bool> addIngredient(Ingredient newIngredient) async {
    try {
      final body = newIngredient.toJson();
      final response = await _apiClient.post(
          '/api/refrigerators/${newIngredient.refrigeratorId}/items',
          body: body
      );
      if (response.statusCode == 201) {
        await fetchIngredientsForId(newIngredient.refrigeratorId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateIngredient(Ingredient ingredientToUpdate) async {
    try {
      final body = {
        'name': ingredientToUpdate.name,
        'expiryDate': DateFormat('yyyy-MM-dd').format(ingredientToUpdate.expiryDate),
        'quantity': ingredientToUpdate.quantity,
        'category': ingredientToUpdate.category,
        'refrigeratorId': ingredientToUpdate.refrigeratorId,
      };
      final response = await _apiClient.put('/api/items/${ingredientToUpdate.id}', body: body);
      if (response.statusCode == 200) {
        await fetchAllIngredients();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteIngredient(int id) async {
    try {
      final response = await _apiClient.delete('/api/items/$id');
      if (response.statusCode == 200) {
        _ingredientMap.forEach((key, value) {
          value.removeWhere((ing) => ing.id == id);
        });
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

