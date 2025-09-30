// lib/models/statistics_model.dart

class PopularIngredient {
  final String name;
  final int count;
  final String coupangUrl;

  PopularIngredient({required this.name, required this.count, required this.coupangUrl});

  factory PopularIngredient.fromJson(Map<String, dynamic> json) {
    return PopularIngredient(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      coupangUrl: json['coupangUrl'] ?? '',
    );
  }
}

class PopularRecipe {
  final int id;
  final String name;
  final String thumbnail;
  final int likeCount;
  bool isLiked;
  int viewCount; // [솔루션] 조회수 필드

  PopularRecipe({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.likeCount,
    required this.isLiked,
    this.viewCount = 0, // 기본값 설정
  });

  factory PopularRecipe.fromJson(Map<String, dynamic> json) {
    return PopularRecipe(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      likeCount: (json['likeCount'] ?? 0).toInt(),
      isLiked: json['liked'] ?? false,
      // viewCount는 API에 없으므로, 프론트엔드에서 관리합니다.
    );
  }
}
