// lib/models/ingredient_input_model.dart

import 'package:flutter/material.dart';

// '나만의 레시피 생성' 화면의 동적인 재료/양 입력 UI를 관리하기 위한 모델
class IngredientInputModel {
  final int id; // 각 라인을 구분하기 위한 고유 ID
  final TextEditingController nameController;
  final TextEditingController amountController;

  IngredientInputModel({
    required this.id,
    required this.nameController,
    required this.amountController,
  });
}
