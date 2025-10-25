// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/basic_recipe_item.dart';

class ApiService {
  static const String baseUrl = 'http://10.10.2.2:8080/api'; // (테스트 환경에 맞게 유지)

  // ▼▼▼ 이 메소드 전체를 아래 코드로 교체해주세요 ▼▼▼
  static Future<List<BasicRecipeItem>> searchRecipes(String query) async {
    final url = Uri.parse('$baseUrl/community/search?query=$query');
    print('검색어: $query, 요청 URL: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 1. 서버가 바로 리스트를 주므로, List<dynamic>으로 받습니다.
        final List<dynamic> recipeList = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (recipeList.isNotEmpty) {
          // 2. 바로 리스트를 객체로 변환합니다.
          return recipeList
              .map((item) => BasicRecipeItem.fromJson(item))
              .toList();
        }
        return [];
      } else {
        print('API 요청 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('API 요청 중 에러 발생: $e');
      return [];
    }
  }
}
