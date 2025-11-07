import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../models/refrigerator_model.dart';
import '../common/api_client.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/ocr_service.dart';

class RefrigeratorViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Refrigerator> _refrigerators = [];
  Map<int, List<Ingredient>> _ingredientMap = {};
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _categories = [
    '채소',
    '과일',
    '육류',
    '어패류',
    '유제품',
    '가공식품',
    '음료',
    '곡물',
    '기타',
  ];

  final OcrService _ocrService = OcrService();
  List<Ingredient> _scannedIngredients = [];
  String? _ocrErrorMessage;

  // --- Getters ---
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Refrigerator> get refrigerators => _refrigerators;
  List<String> get categories => _categories;
  List<Ingredient> get scannedIngredients => _scannedIngredients;
  String? get ocrErrorMessage => _ocrErrorMessage;

  List<Ingredient> get ingredients {
    if (_refrigerators.isEmpty) return [];
    final selectedRefrigeratorId = _refrigerators[_selectedIndex].id;
    final ingredients = _ingredientMap[selectedRefrigeratorId] ?? [];
    ingredients.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return ingredients;
  }

  List<Ingredient> get userIngredients =>
      _ingredientMap.values.expand((list) => list).toList();
  // --- Constructor ---
  RefrigeratorViewModel() {}

  Future<void> loadInitialData() {
    return fetchRefrigerators();
  }

  // --- Data Fetching & State Update ---
  Future<void> fetchRefrigerators() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/refrigerators');
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _refrigerators = responseData
            .map((data) => Refrigerator.fromJson(data))
            .toList();
        _selectedIndex = _refrigerators.indexWhere(
          (r) => r.type == RefrigeratorType.main,
        );
        if (_selectedIndex == -1 && _refrigerators.isNotEmpty)
          _selectedIndex = 0;
        if (_refrigerators.isNotEmpty) {
          await fetchAllIngredients();
        }
      } else {
        _errorMessage = '냉장고 목록 로딩 실패';
      }
    } catch (e) {
      _errorMessage = '냉장고 목록 로딩 중 오류 발생';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllIngredients() async {
    _ingredientMap = {};
    for (var fridge in _refrigerators) {
      await _fetchIngredientsForId(fridge.id);
    }
    notifyListeners();
  }

  Future<void> _fetchIngredientsForId(int refrigeratorId) async {
    try {
      final response = await _apiClient.get(
        '/api/refrigerators/$refrigeratorId/items',
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _ingredientMap[refrigeratorId] = responseData
            .map((data) => Ingredient.fromJson(data, refrigeratorId))
            .toList();
      }
    } catch (e) {
      _ingredientMap[refrigeratorId] = [];
    }
  }

  // --- UI Control ---
  Future<void> selectRefrigerator(int index) async {
    _selectedIndex = index;
    notifyListeners();
  }

  void changeRefrigeratorImage(int index, String newImage) {
    _refrigerators[index].currentImage = newImage;
    notifyListeners();
  }

  // --- CRUD Methods ---
  Future<bool> addIngredient(Ingredient newIngredient) async {
    try {
      final response = await _apiClient.post(
        '/api/refrigerators/${newIngredient.refrigeratorId}/items',
        body: newIngredient.toJson(),
      );
      if (response.statusCode == 201) {
        await fetchAllIngredients();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateIngredient(Ingredient ingredientToUpdate) async {
    try {
      // [수정] 보내주신 코드의 body 생성 로직을 다시 반영했습니다.
      final body = {
        'name': ingredientToUpdate.name,
        'expiryDate': DateFormat(
          'yyyy-MM-dd',
        ).format(ingredientToUpdate.expiryDate),
        'quantity': ingredientToUpdate.quantity,
        'category': ingredientToUpdate.category,
        'refrigeratorId': ingredientToUpdate.refrigeratorId,
      };
      final response = await _apiClient.put(
        '/api/items/${ingredientToUpdate.id}',
        body: body,
      );
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
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchAllIngredients();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // [추가] OCR 스캔 시작 메소드
  Future<bool> startOcrScan(File imageFile) async {
    _isLoading = true;
    _ocrErrorMessage = null;
    notifyListeners();

    try {
      final itemNames = await _ocrService.scanReceipt(imageFile);
      if (itemNames.isEmpty) {
        _ocrErrorMessage = "영수증에서 식재료를 찾지 못했어요.\n다른 사진으로 시도해보세요.";
        return false;
      }

      // OCR 결과(문자열 리스트)를 Ingredient 객체 리스트로 변환
      final defaultExpiryDate = DateTime.now().add(const Duration(days: 7));
      final defaultRefrigeratorId = refrigerators[selectedIndex].id;

      _scannedIngredients = itemNames
          .map(
            (name) => Ingredient(
              id: 0, // 임시 ID
              name: name,
              expiryDate: defaultExpiryDate,
              quantity: 1, // 기본 수량 1
              registrationDate: DateTime.now(),
              category: '기타', // 기본 카테고리
              refrigeratorId: defaultRefrigeratorId,
            ),
          )
          .toList();

      return true;
    } catch (e) {
      _ocrErrorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // [추가] 스캔된 재료 목록 전체 저장
  Future<bool> addAllScannedIngredients() async {
    _isLoading = true;
    notifyListeners();

    bool allSuccess = true;
    for (var ingredient in _scannedIngredients) {
      final success = await addIngredient(ingredient);
      if (!success) {
        allSuccess = false;
        // 실패 시 처리 (예: 사용자에게 알림)
      }
    }

    _scannedIngredients.clear(); // 임시 목록 비우기
    _isLoading = false;
    notifyListeners();

    // 모든 재료가 추가된 후, 현재 냉장고의 재료 목록을 한번 더 갱신
    await _fetchIngredientsForId(refrigerators[selectedIndex].id);
    return allSuccess;
  }
}
