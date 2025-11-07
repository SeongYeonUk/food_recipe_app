// lib/screens/community/community_data.dart

import 'package:flutter/material.dart';
import '../community_screen.dart';
import 'recipe_showcase_screen.dart';
import 'recipe_review_screen.dart';

// 커뮤니티 상단 카테고리 정의
final List<Map<String, dynamic>> communityCategories = [
  {'label': '오늘의 출석', 'color': Colors.red, 'screen': const CommunityDetailScreen(title: '오늘의 출석')},
  {'label': '통계 리포트', 'color': Colors.orange, 'screen': const CommunityDetailScreen(title: '통계 리포트')},
  {'label': '식재료 공유', 'color': Colors.lightGreen, 'screen': const CommunityDetailScreen(title: '식재료 공유')},
  {'label': '식재료 꿀팁', 'color': Colors.green, 'screen': const CommunityDetailScreen(title: '식재료 꿀팁')},
  {'label': '레시피 자랑', 'color': Colors.green, 'screen': const RecipeShowcaseScreen()},
  {'label': '레시피 후기', 'color': Colors.teal, 'screen': const RecipeReviewScreen()},
  {'label': '오늘의 레시피', 'color': Colors.lightBlue, 'screen': const CommunityDetailScreen(title: '오늘의 레시피')},
  {'label': '전문가 레시피', 'color': Colors.blue, 'screen': const CommunityDetailScreen(title: '전문가 레시피')},
  {'label': '정보/추천', 'color': Colors.cyan, 'screen': const CommunityDetailScreen(title: '정보/추천')},
  {'label': '챌린지 미션', 'color': Colors.indigo, 'screen': const CommunityDetailScreen(title: '챌린지 미션')},
  {'label': '냉장고 챗봇', 'color': Colors.purple, 'screen': const CommunityDetailScreen(title: '냉장고 챗봇')},
  {'label': '이벤트', 'color': Colors.pink, 'screen': const CommunityDetailScreen(title: '이벤트')},
];
