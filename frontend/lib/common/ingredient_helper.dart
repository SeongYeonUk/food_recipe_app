import 'package:flutter/material.dart';

class IngredientHelper {
  static const String _basePath = 'asset/img/imoticon/';

  // Standard category list used across UI
  static const List<String> categories = [
    '채소', '과일', '육류', '유제품', '음료', '가공식품', '조미료', '기타'
  ];

  // Map category -> filename prefix and icon count
  static const Map<String, (String prefix, int count)> _iconMeta = {
    '채소': ('채소_', 5),
    '과일': ('과일_', 4),
    '육류': ('육류_', 2),
    '유제품': ('유제품_', 2),
    '음료': ('음료_', 4),
    '가공식품': ('가공식품_', 3),
    '조미료': ('조미료_', 2),
    '기타': ('기타_', 1),
  };

  static int getIconCountForCategory(String category) {
    return _iconMeta[category]?.$2 ?? 1;
  }

  static String getImagePath(String category, int iconIndex) {
    final meta = _iconMeta[category] ?? _iconMeta['기타']!;
    final idx = iconIndex.clamp(0, meta.$2 - 1);
    return '$_basePath${meta.$1}$idx.png';
  }

  static String getImagePathForCategory(String category) => getImagePath(category, 0);

  static Icon? getWarningIcon(int dDay) {
    if (dDay <= 3) {
      return const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18);
    } else if (dDay <= 7) {
      return const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18);
    }
    return null;
  }
}

