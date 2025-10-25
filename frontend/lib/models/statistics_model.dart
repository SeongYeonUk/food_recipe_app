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
  final bool isLiked; // 서버로부터 받는 '좋아요' 여부
  int viewCount; // 화면에서 임시로 증가시킬 수 있으므로 final이 아님

  PopularRecipe({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.likeCount,
    required this.isLiked,
    this.viewCount = 0,
  });

  // [수정 포인트 1] 서버의 JSON 키값과 정확하게 일치하는 fromJson 생성자
  factory PopularRecipe.fromJson(Map<String, dynamic> json) {
    return PopularRecipe(
      id: json['id'] ?? 0,
      name: json['name'] ?? '이름 없음',
      thumbnail: json['thumbnail'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['liked'] ?? false, // 서버 DTO의 isLiked 필드와 이름 일치
    );
  }

  // [수정 포인트 2] ViewModel이 상태를 안전하게 업데이트하기 위한 copyWith 메서드
  PopularRecipe copyWith({
    int? id,
    String? name,
    String? thumbnail,
    int? likeCount,
    bool? isLiked,
    int? viewCount,
  }) {
    return PopularRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnail: thumbnail ?? this.thumbnail,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
