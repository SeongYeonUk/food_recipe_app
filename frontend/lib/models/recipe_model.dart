// lib/models/recipe_model.dart

import 'package:flutter/material.dart';

enum ReactionState { none, liked, disliked }

class Recipe {
  final int id;
  final String name;
  final List<String> ingredients;
  final bool isCustom;
  final List<String> instructions;
  int likes;
  ReactionState userReaction;
  final String imageUrl;
  final String cookingTime;
  final String authorNickname;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.isCustom,
    required this.instructions,
    this.likes = 0,
    this.userReaction = ReactionState.none,
    required this.imageUrl,
    required this.cookingTime,
    required this.authorNickname,
  });

  // [최종 솔루션] 서버로부터 어떤 데이터가 오더라도 안전하게 파싱하는 최종 버전
  factory Recipe.fromJson(Map<String, dynamic> json) {

    // ingredients 필드를 안전하게 파싱합니다.
    List<String> ingredientsList = [];
    if (json['ingredients'] is List) {
      // 1. 서버가 정상적인 리스트(List)를 보냈을 경우
      ingredientsList = List<String>.from(json['ingredients']);
    } else if (json['ingredients'] is String) {
      // 2. 서버가 통짜 문자열(String)을 보냈을 경우 (DB 데이터 등)
      ingredientsList = json['ingredients'].split(',').map((e) => e.trim()).toList();
    }

    // instructions 필드도 동일하게 안전하게 파싱합니다.
    List<String> instructionsList = [];
    if (json['instructions'] is List) {
      instructionsList = List<String>.from(json['instructions']);
    } else if (json['instructions'] is String) {
      instructionsList = json['instructions'].split('\n').map((e) => e.trim()).toList();
    }

    // userReaction 필드를 안전하게 파싱합니다.
    ReactionState reaction = ReactionState.none;
    if (json['userReaction'] == 'liked') {
      reaction = ReactionState.liked;
    } else if (json['userReaction'] == 'disliked') {
      reaction = ReactionState.disliked;
    }

    // isCustom 필드를 안전하게 파싱합니다. (is_custom 과 custom 모두 처리)
    bool isCustomValue = false;
    final customField = json['custom'] ?? json['is_custom'];
    if (customField is bool) {
      isCustomValue = customField;
    } else if (customField == 1) {
      isCustomValue = true;
    }

    return Recipe(
      // 백엔드 DTO(RecipeDetailResponseDto)의 필드명을 기준으로 합니다.
      id: json['recipeId'] ?? 0,
      name: json['recipeName'] ?? '이름 없음',
      ingredients: ingredientsList, // 안전하게 파싱된 리스트 사용
      instructions: instructionsList, // 안전하게 파싱된 리스트 사용
      likes: json['likeCount'] ?? 0,
      cookingTime: json['cookingTime'] ?? '0분',
      imageUrl: json['imageUrl'] ?? '',
      isCustom: isCustomValue,
      userReaction: reaction,
      authorNickname: json['user']?['nickname'] ?? '알 수 없음',
    );
  }
}



