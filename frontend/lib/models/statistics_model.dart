// lib/models/statistics_model.dart

// --- 인기 재료 모델 (백엔드 PopularIngredientDto에 맞춰 정의) ---
class PopularIngredient {
  final String name;
  final int count;
  // final String coupangUrl;

  PopularIngredient({
    required this.name,
    required this.count,
    // required this.coupangUrl,
  });

  factory PopularIngredient.fromJson(Map<String, dynamic> json) {
    return PopularIngredient(
      name: json['name'] ?? '알 수 없는 재료',
      count: json['count'] ?? 0,
      // coupangUrl: json['coupangUrl'] ?? '',
    );
  }
}

// --- 인기 레시피 모델 (백엔드 PopularRecipeDto에 맞춰 정의) ---
class PopularRecipe {
  final int id;
  final String name;
  final String thumbnail; // 백엔드 필드명 'thumbnail'
  final int likeCount;
  final bool isLiked; // 백엔드 필드명 'isLiked'

  PopularRecipe({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.likeCount,
    required this.isLiked,
  });

  factory PopularRecipe.fromJson(Map<String, dynamic> json) {
    return PopularRecipe(
      id: json['id'] ?? 0,
      name: json['name'] ?? '이름 없음',
      thumbnail: json['thumbnail'] ?? '', // 'thumbnail' 필드에서 데이터 추출
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false, // 'isLiked' 필드에서 데이터 추출
    );
  }
}
