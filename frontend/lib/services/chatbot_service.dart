import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../common/api_client.dart';
import '../models/basic_recipe_item.dart';
import '../models/ingredient_model.dart';
import '../models/refrigerator_model.dart';

/// 레시피 추천 결과 모델 (수정됨: message 필드 추가)
class RecipeRecommendationResult {
  final List<String> suggestedIngredients;
  final List<String> matchingIngredients;
  final List<BasicRecipeItem> recipes;
  final String? message; // 👈 [신규] 챗봇의 텍스트 답변 (대체재료 등)

  RecipeRecommendationResult({
    required this.suggestedIngredients,
    required this.matchingIngredients,
    required this.recipes,
    this.message,
  });

  factory RecipeRecommendationResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSuggested =
        json['suggestedIngredients'] as List<dynamic>? ?? [];
    final List<dynamic> rawMatching =
        json['matchingIngredients'] as List<dynamic>? ?? [];
    final List<dynamic> rawRecipes = json['recipes'] as List<dynamic>? ?? [];

    return RecipeRecommendationResult(
      suggestedIngredients: rawSuggested.map((e) => e.toString()).toList(),
      matchingIngredients: rawMatching.map((e) => e.toString()).toList(),
      recipes: rawRecipes
          .map((e) => BasicRecipeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?, // 👈 메시지 파싱 추가
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
      timerSeconds: json['timerSeconds'] == null
          ? null
          : int.tryParse(json['timerSeconds'].toString()),
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

  /// 1. [수정됨] 통합 대화 요청 (/ask 사용)
  /// 레시피 추천과 일반 질문(대체재료)을 모두 처리합니다.
  Future<RecipeRecommendationResult?> recommend(String sttText) async {
    // 👇 [핵심] /recommend 대신 /ask 호출
    final res = await _client.post(
      '/api/chatbot/ask',
      body: {'sttText': sttText},
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));

      // Case A: 챗봇 답변(message)만 온 경우 (대체재료 질문 등)
      if (data.containsKey('message') && !data.containsKey('recipes')) {
        return RecipeRecommendationResult(
          suggestedIngredients: [],
          matchingIngredients: [],
          recipes: [],
          message: data['message'], // 답변 내용 담기
        );
      }

      // Case B: 레시피 목록이 온 경우
      return RecipeRecommendationResult.fromJson(data);
    }
    return null;
  }

  /// 2. 조리 명령 (/cooking)
  Future<CookingResponse?> handleCooking(String sttText) async {
    final res = await _client.post(
      '/api/chatbot/cooking',
      body: {'sttText': sttText},
    );
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return CookingResponse.fromJson(data);
    }
    return null;
  }

  /// 3. 유통기한 추천 (/expiry/recommend)
  Future<ExpiryRecommendationResult?> recommendExpiry({
    List<String>? ingredientNames,
  }) async {
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

  /// 4. 임박 식재료 조회
  Future<List<Ingredient>> fetchExpiringIngredients({
    int withinDays = 7,
  }) async {
    try {
      final fridgeRes = await _client.get('/api/refrigerators');
      if (fridgeRes.statusCode != 200) return [];
      final List<dynamic> fridgeJson = jsonDecode(
        utf8.decode(fridgeRes.bodyBytes),
      );
      final fridges = fridgeJson
          .map((e) => Refrigerator.fromJson(e as Map<String, dynamic>))
          .toList();

      final List<Ingredient> all = [];
      for (final fridge in fridges) {
        final itemsRes = await _client.get(
          '/api/refrigerators/${fridge.id}/items',
        );
        if (itemsRes.statusCode != 200) continue;
        final List<dynamic> itemsJson = jsonDecode(
          utf8.decode(itemsRes.bodyBytes),
        );
        final items = itemsJson
            .map(
              (data) => Ingredient.fromJson(
                Map<String, dynamic>.from(data as Map),
                fridge.id,
              ),
            )
            .toList();
        all.addAll(items);
      }

      all.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return all.where((i) => i.dDay <= withinDays).toList();
    } catch (_) {
      return [];
    }
  }

  /// 5. 클릭으로 조리 시작
  Future<CookingResponse?> startCookingById(String recipeId) async {
    final res = await _client.post(
      '/api/chatbot/cooking/start/$recipeId',
      body: {},
    );
    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return CookingResponse.fromJson(data);
    }
    return null;
  }

  /// 6. TTS 생성
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
