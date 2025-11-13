// 📁 lib/viewmodels/refrigerator_viewmodel.dart (최적화 완료)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/api_client.dart';
import '../models/ingredient_model.dart';
import '../models/refrigerator_model.dart';
import '../services/ocr_service.dart';

class RefrigeratorViewModel with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Refrigerator> _refrigerators = [];
  Map<int, List<Ingredient>> _ingredientMap = {};
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;

  final OcrService _ocrService = OcrService();
  List<Ingredient> _scannedIngredients = [];
  String? _ocrErrorMessage;

  // --- ✅ 1. UI 최적화를 위해 미리 계산된 리스트 변수 추가 ---
  List<Ingredient> _urgentIngredients = [];
  List<Ingredient> _soonIngredients = [];
  Map<String, List<Ingredient>> _ingredientsByCategory = {};
  List<String> _categories = [];
  // ---

  // Getters
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Refrigerator> get refrigerators => _refrigerators;
  List<Ingredient> get scannedIngredients => _scannedIngredients;
  String? get ocrErrorMessage => _ocrErrorMessage;

  // --- ✅ 2. UI가 사용할 "미리 계산된" Getters ---
  List<String> get categories => _categories;
  List<Ingredient> get urgentIngredients => _urgentIngredients;
  List<Ingredient> get soonIngredients => _soonIngredients;
  Map<String, List<Ingredient>> get ingredientsByCategory =>
      _ingredientsByCategory;
  // ---

  // (기존 ingredients Getter: 정렬 기능 유지)
  List<Ingredient> get ingredients {
    if (_refrigerators.isEmpty) return [];
    final selectedRefrigeratorId = _refrigerators[_selectedIndex].id;
    final ingredients = _ingredientMap[selectedRefrigeratorId] ?? [];
    // (정렬은 여기서 해도 성능에 큰 영향 없음)
    ingredients.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return ingredients;
  }

  List<Ingredient> get userIngredients =>
      _ingredientMap.values.expand((list) => list).toList();

  RefrigeratorViewModel();

  Future<void> loadInitialData() async {
    await fetchRefrigerators();
  }

  // Data fetching
  Future<void> fetchRefrigerators() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    print(">>> [ViewModel] 1. 냉장고 목록 로드 시작... (/api/refrigerators)"); // 👈 1.

    try {
      final response = await _apiClient.get('/api/refrigerators');
      print("<<< [ViewModel] 2. 냉장고 목록 응답 받음: ${response.statusCode}"); // 👈 2.
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
        if (_selectedIndex == -1 && _refrigerators.isNotEmpty) {
          _selectedIndex = 0;
        }
        if (_refrigerators.isNotEmpty) {
          await fetchAllIngredients(); // ✅ 내부에서 _processIngredients... 호출
        }
      } else {
        _errorMessage = '냉장고 목록 로딩 실패';
        _errorMessage = '냉장고 목록 로딩 실패 (상태 코드: ${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = '냉장고 목록 로딩 중 오류';

      // ✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅
      // ⭐️⭐️⭐️ 여기가 가장 중요합니다 ⭐️⭐️⭐️
      // ✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅
      print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
      print("XXX [ViewModel] fetchRefrigerators 실패!");
      print("XXX [ViewModel] 잡힌 오류(e): $e"); // 👈 4. 정확한 오류 내용 출력
      print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
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

    // ✅ 3. 모든 재료를 가져온 후, "현재 선택된" 냉장고 기준으로 UI 데이터 계산
    _processIngredientsForSelectedFridge();

    await _cacheIngredientsForNotifications();
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
    } catch (_) {
      _ingredientMap[refrigeratorId] = [];
    }
  }

  // ✅ 4. (핵심) "미리 계산" 로직
  void _processIngredientsForSelectedFridge() {
    // 1. 현재 선택된 냉장고의 재료 목록 가져오기
    if (_refrigerators.isEmpty) return;
    final selectedRefrigeratorId = _refrigerators[_selectedIndex].id;
    final currentIngredients = _ingredientMap[selectedRefrigeratorId] ?? [];

    // 2. 이전 계산 결과 초기화
    _urgentIngredients.clear();
    _soonIngredients.clear();
    _ingredientsByCategory.clear();
    final categorySet = <String>{};

    // 3. 재료 목록을 "한 번만" 순회하면서 모든 UI용 데이터 계산
    for (final ingredient in currentIngredients) {
      final dDay = ingredient.dDay;

      // (a) 유통기한 리스트 계산
      if (dDay <= 3) {
        _urgentIngredients.add(ingredient);
      } else if (dDay > 3 && dDay <= 7) {
        _soonIngredients.add(ingredient);
      }

      // (b) 카테고리별 맵 계산
      final category = ingredient.category;
      if (!_ingredientsByCategory.containsKey(category)) {
        _ingredientsByCategory[category] = [];
        categorySet.add(category);
      }
      _ingredientsByCategory[category]!.add(ingredient);
    }

    // 4. 카테고리 리스트 업데이트
    _categories = categorySet.toList()..sort();
  }

  Future<void> _cacheIngredientsForNotifications() async {
    try {
      final all = _ingredientMap.values.expand((list) => list).toList();
      final data = all
          .map(
            (i) => {
              'id': i.id,
              'name': i.name,
              'expiryDate': i.expiryDate.toIso8601String(),
            },
          )
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ingredients', jsonEncode(data));
    } catch (_) {
      // ignore caching errors
    }
  }

  // UI helpers
  Future<void> selectRefrigerator(int index) async {
    _selectedIndex = index;
    // ✅ 5. 탭 전환 시, 해당 탭의 재료 기준으로 "미리 계산" 다시 실행
    _processIngredientsForSelectedFridge();
    notifyListeners();
  }

  void changeRefrigeratorImage(int index, String newImage) {
    _refrigerators[index].currentImage = newImage;
    notifyListeners();
  }

  // CRUD
  Future<bool> addIngredient(Ingredient newIngredient) async {
    try {
      final body = newIngredient.toJson();
      var response = await _apiClient.post(
        '/api/refrigerators/${newIngredient.refrigeratorId}/items',
        body: body,
      );
      if (response.statusCode != 201 && body['category'] == '곡류') {
        final retryBody = Map<String, dynamic>.from(body)..['category'] = '곡물';
        response = await _apiClient.post(
          '/api/refrigerators/${newIngredient.refrigeratorId}/items',
          body: retryBody,
        );
      }
      if (response.statusCode == 201) {
        await fetchAllIngredients(); // ✅ 성공 시 UI 갱신 (계산 포함)
        return true;
      }
      print('addIngredient failed: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('addIngredient exception: $e');
      return false;
    }
  }

  Future<bool> updateIngredient(Ingredient ingredientToUpdate) async {
    try {
      final body = {
        'name': ingredientToUpdate.name,
        'expiryDate': DateFormat(
          'yyyy-MM-dd',
        ).format(ingredientToUpdate.expiryDate),
        'quantity': ingredientToUpdate.quantity,
        'category': ingredientToUpdate.category,
        'refrigeratorId': ingredientToUpdate.refrigeratorId,
        'iconIndex': ingredientToUpdate.iconIndex,
      };
      var response = await _apiClient.put(
        '/api/items/${ingredientToUpdate.id}',
        body: body,
      );
      if (response.statusCode != 200 && body['category'] == '곡류') {
        final retryBody = Map<String, dynamic>.from(body)..['category'] = '곡물';
        response = await _apiClient.put(
          '/api/items/${ingredientToUpdate.id}',
          body: retryBody,
        );
      }
      if (response.statusCode == 200) {
        await fetchAllIngredients(); // ✅ 성공 시 UI 갱신 (계산 포함)
        return true;
      }
      print('updateIngredient failed: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('updateIngredient exception: $e');
      return false;
    }
  }

  Future<bool> deleteIngredient(int id) async {
    try {
      final response = await _apiClient.delete('/api/items/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchAllIngredients(); // ✅ 성공 시 UI 갱신 (계산 포함)
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // OCR flow
  Future<bool> startOcrScan(File imageFile) async {
    _isLoading = true;
    _ocrErrorMessage = null;
    notifyListeners();

    try {
      final itemNames = await _ocrService.scanReceipt(imageFile);
      if (itemNames.isEmpty) {
        _ocrErrorMessage =
            '영수증에서 재료를 찾지 못했어요.'
            '\n다른 사진으로 시도해 보세요.';
        return false;
      }

      final defaultExpiryDate = DateTime.now().add(const Duration(days: 7));
      final defaultRefrigeratorId = refrigerators[selectedIndex].id;

      _scannedIngredients = itemNames
          .map(
            (name) => Ingredient(
              id: 0,
              name: name,
              expiryDate: defaultExpiryDate,
              quantity: 1,
              registrationDate: DateTime.now(),
              category: '기타',
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

  Future<bool> addAllScannedIngredients() async {
    _isLoading = true;
    notifyListeners();

    bool allSuccess = true;
    for (var ingredient in _scannedIngredients) {
      final success = await addIngredient(ingredient);
      if (!success) {
        allSuccess = false;
      }
    }

    _scannedIngredients.clear();
    _isLoading = false;

    if (_refrigerators.isNotEmpty) {
      await fetchAllIngredients();
    } else {
      notifyListeners();
    }
    return allSuccess;
  }
}
