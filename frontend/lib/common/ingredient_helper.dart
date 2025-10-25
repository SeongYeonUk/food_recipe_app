import 'package:flutter/material.dart';

class IngredientHelper {
  // 카테고리 이름에 맞는 이미지 파일 경로를 반환
  static String getImagePathForCategory(String category) {
    const String basePath = 'asset/img/imoticon/';
    switch (category) {
      case '가공식품': return '${basePath}가공식품_0.png';
      case '과일': return '${basePath}과일_0.png';
      case '기타': return '${basePath}기타_0.png';
      case '어패류': return '${basePath}어패류_0.png';
      case '유제품': return '${basePath}유제품_0.png';
      case '육류': return '${basePath}육류_0.png';
      case '음료': return '${basePath}음료_0.png';
      case '채소': return '${basePath}채소_0.png';
      default: return '${basePath}기타_0.png';
    }
  }

  // D-Day에 따라 주의/임박 아이콘을 반환
  static Icon? getWarningIcon(int dDay) {
    if (dDay <= 3) {
      return const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18);
    } else if (dDay <= 7) {
      return Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18);
    }
    return null;
  }
}

