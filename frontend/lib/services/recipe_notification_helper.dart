// lib/services/recipe_notification_helper.dart
//
// Helper utilities to fetch the highest ranked recommended recipe so that
// notifications can surface an actual suggestion instead of hard-coded text.

import 'dart:convert';

import 'package:food_recipe_app/common/api_client.dart';

class RecipeNotificationInfo {
  final int id;
  final String name;
  final String description;
  final String cookingTime;
  final String imageUrl;

  const RecipeNotificationInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.cookingTime,
    required this.imageUrl,
  });

  factory RecipeNotificationInfo.fromJson(Map<String, dynamic> json) {
    final dynamic idRaw = json['recipeId'] ?? json['id'];
    int id = 0;
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is String) {
      id = int.tryParse(idRaw) ?? 0;
    }

    return RecipeNotificationInfo(
      id: id,
      name: (json['recipeName'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      cookingTime: (json['cookingTime'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
    );
  }

  String get displayName => name.isNotEmpty ? name : '오늘의 추천 레시피';

  String buildNotificationBody() {
    final trimmedDesc = description.trim();
    if (trimmedDesc.isNotEmpty) {
      return trimmedDesc.length > 80 ? '${trimmedDesc.substring(0, 80)}…' : trimmedDesc;
    }

    final trimmedTime = cookingTime.trim();
    if (trimmedTime.isNotEmpty && trimmedTime != '0분') {
      return '$displayName · $trimmedTime';
    }

    return '$displayName를 확인해보세요';
  }
}

class RecipeNotificationHelper {
  static Future<RecipeNotificationInfo?> fetchTopRecommendation() async {
    try {
      final response = await ApiClient().get('/api/recipes/recommendations');
      if (response.statusCode != 200) {
        return null;
      }
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic>) {
          return RecipeNotificationInfo.fromJson(first);
        } else if (first is Map) {
          return RecipeNotificationInfo.fromJson(
            first.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      }
    } catch (_) {
      // Ignore network/decoding issues so notification logic can fall back gracefully.
    }
    return null;
  }
}
