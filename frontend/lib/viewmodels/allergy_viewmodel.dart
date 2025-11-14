import 'dart:convert';

import 'package:flutter/material.dart';
import '../common/api_client.dart';
import '../models/allergy_ingredient_model.dart';

class AllergyViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;
  List<AllergyIngredientModel> _items = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AllergyIngredientModel> get items => List.unmodifiable(_items);

  Future<void> loadAllergies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/allergies');
      if (response.statusCode != 200) {
        throw Exception('알레르기 식재료 목록을 불러오지 못했습니다.');
      }
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      _items = data.map((e) => AllergyIngredientModel.fromJson(e)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAllergy(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _errorMessage = '식재료 이름을 입력해 주세요.';
      notifyListeners();
      return;
    }
    _errorMessage = null;
    notifyListeners();
    final response = await _apiClient.post('/api/allergies', body: {'name': trimmed});
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(utf8.decode(response.bodyBytes));
      final newItem = AllergyIngredientModel.fromJson(json);
      _items = [..._items, newItem];
      notifyListeners();
    } else {
      _errorMessage = utf8.decode(response.bodyBytes);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> deleteAllergy(int id) async {
    final response = await _apiClient.delete('/api/allergies/$id');
    if (response.statusCode == 204) {
      _items = _items.where((item) => item.id != id).toList();
      notifyListeners();
    } else {
      _errorMessage = utf8.decode(response.bodyBytes);
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
}
