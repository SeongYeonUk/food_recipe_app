// lib/viewmodels/refrigerator_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/ingredient_model.dart'; // 모델 경로를 확인해주세요.

class RefrigeratorViewModel with ChangeNotifier {
  int _selectedIndex = 1;
  int get selectedIndex => _selectedIndex;

  final List<Refrigerator> _refrigerators = [
    Refrigerator(name: '냉동실', currentImage: 'asset/img/Refrigerator/냉동실1.png', availableImages: ['asset/img/Refrigerator/냉동실1.png', 'asset/img/Refrigerator/냉동실2.png', 'asset/img/Refrigerator/냉동실3.png']),
    Refrigerator(name: '메인냉장고', currentImage: 'asset/img/Refrigerator/냉장고1.png', availableImages: ['asset/img/Refrigerator/냉장고1.png', 'asset/img/Refrigerator/냉장고2.png', 'asset/img/Refrigerator/냉장고3.png', 'asset/img/Refrigerator/냉장고4.png']),
    Refrigerator(name: '김치냉장고', currentImage: 'asset/img/Refrigerator/김치냉장고1.png', availableImages: ['asset/img/Refrigerator/김치냉장고1.png', 'asset/img/Refrigerator/김치냉장고2.png']),
  ];
  List<Refrigerator> get refrigerators => _refrigerators;

  final List<Ingredient> _allIngredients = [
    Ingredient(id: 1, name: '계란', expiryDate: DateTime.now().add(const Duration(days: 10)), quantity: 5, registrationDate: DateTime.now(), category: '유제품', refrigeratorType: '메인냉장고'),
    Ingredient(id: 2, name: '우유', expiryDate: DateTime.now().add(const Duration(days: 2)), quantity: 1, registrationDate: DateTime.now(), category: '유제품', refrigeratorType: '메인냉장고'),
    Ingredient(id: 3, name: '양파', expiryDate: DateTime.now().subtract(const Duration(days: 1)), quantity: 2, registrationDate: DateTime.now(), category: '채소', refrigeratorType: '메인냉장고'),
    Ingredient(id: 4, name: '냉동 만두', expiryDate: DateTime.now().add(const Duration(days: 90)), quantity: 1, registrationDate: DateTime.now(), category: '가공식품', refrigeratorType: '냉동실'),
    Ingredient(id: 5, name: '배추김치', expiryDate: DateTime.now().add(const Duration(days: 38)), quantity: 1, registrationDate: DateTime.now(), category: '김치', refrigeratorType: '김치냉장고'),
  ];

  List<Ingredient> get filteredIngredients {
    final filtered = _allIngredients.where((ing) => ing.refrigeratorType == _refrigerators[_selectedIndex].name).toList();
    filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return filtered;
  }

  void selectRefrigerator(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void changeRefrigeratorImage(int index, String newImage) {
    _refrigerators[index].currentImage = newImage;
    notifyListeners();
  }

  void addOrUpdateIngredient(Ingredient newIngredient, {Ingredient? originalIngredient}) {
    if (originalIngredient != null) {
      final index = _allIngredients.indexWhere((ing) => ing.id == originalIngredient.id);
      if (index != -1) _allIngredients[index] = newIngredient;
    } else {
      _allIngredients.add(newIngredient);
    }
    notifyListeners();
  }

  void deleteIngredient(int id) {
    _allIngredients.removeWhere((ing) => ing.id == id);
    notifyListeners();
  }
}
