import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../common/api_client.dart';
import '../models/basic_recipe_item.dart';
import '../models/ingredient_model.dart';
import '../models/refrigerator_model.dart';

class RecipeRecommendationResult {
  final List<String> suggestedIngredients;
  final List<String> matchingIngredients;
  final List<BasicRecipeItem> recipes;

  RecipeRecommendationResult({
    required this.suggestedIngredients,
    required this.matchingIngredients,
    required this.recipes,
  });

  factory RecipeRecommendationResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSuggested = json['suggestedIngredients'] as List<dynamic>? ?? [];
    final List<dynamic> rawMatching = json['matchingIngredients'] as List<dynamic>? ?? [];
    final List<dynamic> rawRecipes = json['recipes'] as List<dynamic>? ?? [];

    return RecipeRecommendationResult(
      suggestedIngredients: rawSuggested.map((e) => e.toString()).toList(),
      matchingIngredients: rawMatching.map((e) => e.toString()).toList(),
      recipes: rawRecipes.map((e) => BasicRecipeItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class CookingResponse {
  final String message;
  final String actionType;
  final int? timerSeconds;

  CookingResponse({
    required this.message,
    required this.actionType,
    this.timerSeconds,
  });

  factory CookingResponse.fromJson(Map<String, dynamic> json) {
    return CookingResponse(
      message: json['message']?.toString() ?? '',
      actionType: json['actionType']?.toString() ?? 'SPEAK',
      timerSeconds: json['timerSeconds'] == null ? null : int.tryParse(json['timerSeconds'].toString()),
    );
  }
}

class ExpiryRecommendation {
  final String name;
  final String recommendedDate;
  final bool updated;

  ExpiryRecommendation({
    required this.name,
    required this.recommendedDate,
    required this.updated,
  });

  factory ExpiryRecommendation.fromJson(Map<String, dynamic> json) {
    return ExpiryRecommendation(
      name: json['name']?.toString() ?? '',
      recommendedDate: json['recommendedDate']?.toString() ?? '',
      updated: json['updated'] == true,
    );
  }
}

class ExpiryRecommendationResult {
  final List<ExpiryRecommendation> recommendations;

  ExpiryRecommendationResult({required this.recommendations});

  factory ExpiryRecommendationResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['recommendations'] as List<dynamic>? ?? [];
    return ExpiryRecommendationResult(
      recommendations: raw
          .map((e) => ExpiryRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatbotService {
  final ApiClient _client = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<RecipeRecommendationResult?> recommend(String sttText) async {
    final res = await _client.post('/api/chatbot/recommend', body: {'sttText': sttText});
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return RecipeRecommendationResult.fromJson(data);
    }
    return null;
  }

  Future<CookingResponse?> handleCooking(String sttText) async {
    final res = await _client.post('/api/chatbot/cooking', body: {'sttText': sttText});
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return CookingResponse.fromJson(data);
    }
    return null;
  }

  Future<ExpiryRecommendationResult?> recommendExpiry({List<String>? ingredientNames}) async {
    final body = <String, dynamic>{};
    if (ingredientNames != null) {
      body['ingredientNames'] = ingredientNames;
    }
    final res = await _client.post('/api/chatbot/expiry/recommend', body: body);
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return ExpiryRecommendationResult.fromJson(data);
    }
    return null;
  }

  Future<List<Ingredient>> fetchExpiringIngredients({int withinDays = 7}) async {
    try {
      final fridgeRes = await _client.get('/api/refrigerators');
      if (fridgeRes.statusCode != 200) return [];
      final List<dynamic> fridgeJson = jsonDecode(utf8.decode(fridgeRes.bodyBytes));
      final fridges = fridgeJson.map((e) => Refrigerator.fromJson(e as Map<String, dynamic>)).toList();

      final List<Ingredient> all = [];
      for (final fridge in fridges) {
        final itemsRes = await _client.get('/api/refrigerators/${fridge.id}/items');
        if (itemsRes.statusCode != 200) continue;
        final List<dynamic> itemsJson = jsonDecode(utf8.decode(itemsRes.bodyBytes));
        final items = itemsJson
            .map((data) => Ingredient.fromJson(Map<String, dynamic>.from(data as Map), fridge.id))
            .toList();
        all.addAll(items);
      }

      all.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return all.where((i) => i.dDay <= withinDays).toList();
    } catch (_) {
      return [];
    }
  }

  Future<CookingResponse?> startCookingById(String recipeId) async {
    final res = await _client.post('/api/chatbot/cooking/start/$recipeId', body: {});
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return CookingResponse.fromJson(data);
    }
    return null;
  }

  Future<Uint8List?> synthesizeTts(String text) async {
    final token = await _storage.read(key: 'ACCESS_TOKEN');
    final res = await http.post(
      Uri.parse('${ApiClient.baseUrl}/api/chatbot/tts'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
    return null;
  }
}
