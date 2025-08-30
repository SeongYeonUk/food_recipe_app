// lib/viewmodels/refrigerator_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../common/api_client.dart';

class RefrigeratorViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;

  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // (수정)하드코딩된 목록을 비어있는 리스트로 변경
  List<Refrigerator> _refrigerators = [];
  List<Refrigerator> get refrigerators => _refrigerators;

  List<Ingredient> _ingredients = [];
  List<Ingredient> get filteredIngredients {
    _ingredients.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return _ingredients;
  }

  // [추가]서버에서 냉장고 목록을 가져오는 함수
  Future<void> fetchRefrigerators() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/refrigerators');
      if (response.statusCode == 200) {
        //디버깅용
        print("서버 응답: ${utf8.decode(response.bodyBytes)}");

        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _refrigerators = responseData
            .map((data) => Refrigerator.fromJson(data))
            .toList();

        // 메인냉장고를 찾아 기본 선택 인덱스로 설정
        _selectedIndex = _refrigerators.indexWhere((r) => r.name == '메인냉장고');
        if (_selectedIndex == -1 && _refrigerators.isNotEmpty) {
          _selectedIndex = 0; // 메인냉장고가 없으면 첫 번째 냉장고 선택
        }

        // 냉장고 목록을 성공적으로 불러온 후, 선택된 냉장고의 식재료를 불러옴
        if (_refrigerators.isNotEmpty) {
          await fetchIngredients();
        }
      } else {
        _errorMessage = '냉장고 목록을 불러오지 못했습니다. (코드: ${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = '냉장고 목록 로딩 중 오류 발생: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // (수정) 식재료 목록을 가져오는 함수
  Future<void> fetchIngredients() async {
    // 가져올 냉장고 목록이 없으면 함수를 종료
    if (_refrigerators.isEmpty) {
      _ingredients = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 이제 id는 하드코딩된 값이 아닌, 서버에서 받아온 실제 id
      final refrigeratorId = _refrigerators[_selectedIndex].id;
      final response = await _apiClient.get(
        '/api/refrigerators/$refrigeratorId/items',
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _ingredients = responseData
            .map(
              (data) => Ingredient.fromJson(
                data,
                _refrigerators[_selectedIndex].name,
              ),
            )
            .toList();
      } else {
        _errorMessage = '데이터를 불러오는데 실패했습니다. (코드: ${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = '식재료 로딩 중 오류 발생: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // (수정) 냉장고 선택 함수
  Future<void> selectRefrigerator(int index) async {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners(); // UI가 즉시 선택된 냉장고를 반영하도록 함
    await fetchIngredients(); // 그 다음 식재료를 불러옴
  }

  void changeRefrigeratorImage(int index, String newImage) {
    if (index < _refrigerators.length) {
      _refrigerators[index].currentImage = newImage;
      notifyListeners();
    }
  }

  Future<bool> addIngredient(Ingredient newIngredient) async {
    try {
      final refrigeratorId = _refrigerators
          .firstWhere((r) => r.name == newIngredient.refrigeratorType)
          .id;
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
      // (수정)요청 데이터 보내는 부분

      // 1. ingredientToUpdate.refrigeratorType (예: '메인냉장고')으로 실제 냉장고 ID를 찾습니다.
      final refrigeratorId = _refrigerators
          .firstWhere((r) => r.name == ingredientToUpdate.refrigeratorType)
          .id;

      // 2. 서버로 보낼 JSON 데이터를 만듭니다.
      final body = {
        ...ingredientToUpdate.toJson(), // 기존 데이터 (이름, 수량 등)
        'refrigeratorId': refrigeratorId, // 새로운 냉장고 ID를 추가
      };

      final response = await _apiClient.put(
        '/api/items/${ingredientToUpdate.id}',
        body: body, // 직접 만든 body를 전달
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
      final response = await _apiClient.delete('/api/items/$id'); // API 경로 단순화

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
