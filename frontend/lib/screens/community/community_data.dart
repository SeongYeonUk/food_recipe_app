// lib/screens/community/community_data.dart

import 'package:flutter/material.dart';
import '../community_screen.dart'; // CommunityDetailScreen을 사용하기 위함
import 'recipe_showcase_screen.dart';
import 'recipe_review_screen.dart';

// [솔루션] 12개 카테고리 데이터를 앱 전체에서 공유하기 위한 리스트
final List<Map<String, dynamic>> communityCategories = [
  {'label': '오늘의 출석', 'color': Colors.red.shade400, 'screen': const CommunityDetailScreen(title: '오늘의 출석')},
  {'label': '식생활 리포트', 'color': Colors.orange.shade500, 'screen': const CommunityDetailScreen(title: '식생활 리포트')},
  {'label': '식재료 공유', 'color': Colors.lightGreen.shade500, 'screen': const CommunityDetailScreen(title: '식재료 공유')},
  {'label': '식재료 꿀팁', 'color': Colors.lightGreen.shade500, 'screen': const CommunityDetailScreen(title: '식재료 꿀팁')},
  {'label': '레시피 자랑', 'color': Colors.green.shade400, 'screen': const RecipeShowcaseScreen()},
  {'label': '레시피 후기', 'color': Colors.green.shade400, 'screen': const RecipeReviewScreen()},
  {'label': '오늘의 레시피', 'color': Colors.green.shade800, 'screen': const CommunityDetailScreen(title: '오늘의 레시피')},
  {'label': '전문가 레시피', 'color': Colors.green.shade800, 'screen': const CommunityDetailScreen(title: '전문가 레시피')},
  {'label': '장보기 추천', 'color': Colors.cyan.shade400, 'screen': const CommunityDetailScreen(title: '장보기 추천')},
  {'label': '챌린지 미션', 'color': Colors.indigo.shade500, 'screen': const CommunityDetailScreen(title: '챌린지 미션')},
  {'label': '냉장고 챗봇', 'color': Colors.purple.shade400, 'screen': const CommunityDetailScreen(title: '냉장고 챗봇')},
  {'label': '배지', 'color': Colors.pink.shade400, 'screen': const CommunityDetailScreen(title: '배지')},
];

