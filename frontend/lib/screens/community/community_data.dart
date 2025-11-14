// lib/screens/community/community_data.dart

import 'package:flutter/material.dart';
import '../community_screen.dart';
import 'recipe_showcase_screen.dart';
import 'recipe_review_screen.dart';

// 커뮤니티 상단 카테고리 (라벨/색상)
final List<Map<String, dynamic>> communityCategories = [
  {'label': '레시피 자랑', 'color': Colors.yellow},
  {'label': '레시피 후기', 'color': Colors.orange},
  {'label': '오늘의 레시피', 'color': Colors.green},
  {'label': '전문가 레시피', 'color': Colors.lightBlue},
];
