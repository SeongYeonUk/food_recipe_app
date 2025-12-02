// lib/models/statistics_model.dart

class PopularIngredient {
  final String name;
  final int count;
  final String coupangUrl;

  PopularIngredient({
    required this.name,
    required this.count,
    required this.coupangUrl,
  });

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
  int favoriteCount;
  int viewCount;
  final bool isCustom;
  final bool isLiked; // 서버로부터 받는 '좋아요 여부'
  final String? createdAt; // ISO string

  PopularRecipe({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.likeCount,
    required this.favoriteCount,
    required this.viewCount,
    required this.isCustom,
    required this.isLiked,
    this.createdAt,
  });

  factory PopularRecipe.fromJson(Map<String, dynamic> json) {
    return PopularRecipe(
      id: json['id'] ?? 0,
      name: json['name'] ?? '이름 없음',
      thumbnail: json['thumbnail'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      favoriteCount: json['favoriteCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      isCustom: json['custom'] ?? json['isCustom'] ?? false,
      createdAt: json['createdAt']?.toString(),
      isLiked: json['liked'] ?? false,
    );
  }

  PopularRecipe copyWith({
    int? id,
    String? name,
    String? thumbnail,
    int? likeCount,
    int? favoriteCount,
    int? viewCount,
    bool? isCustom,
    bool? isLiked,
    String? createdAt,
  }) {
    return PopularRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnail: thumbnail ?? this.thumbnail,
      likeCount: likeCount ?? this.likeCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      viewCount: viewCount ?? this.viewCount,
      isCustom: isCustom ?? this.isCustom,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
