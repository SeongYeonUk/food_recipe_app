class PostDetailModel {
  final int postId;
  final String title;
  final String content;
  final String cookTime;
  final String ingredients;
  final String? imageUrl;
  final String authorName;
  final int likeCount;
  final int dislikeCount;
  final int reviewCount;
  final String createdAt; // 서버에서 LocalDateTime 형태로 오지만 일단 String으로 받겠습니다.

  PostDetailModel({
    required this.postId,
    required this.title,
    required this.content,
    required this.cookTime,
    required this.ingredients,
    this.imageUrl,
    required this.authorName,
    required this.likeCount,
    required this.dislikeCount,
    required this.reviewCount,
    required this.createdAt,
  });

  factory PostDetailModel.fromJson(Map<String, dynamic> json) {
    return PostDetailModel(
      postId: json['postId'],
      title: json['title'] ?? '제목 없음',
      content: json['content'] ?? '',
      cookTime: json['cookTime'] ?? '시간 미정',
      ingredients: json['ingredients'] ?? '재료 목록 없음',
      imageUrl: json['imageUrl'],
      authorName: json['authorName'] ?? '익명',
      likeCount: json['likeCount'] ?? 0,
      dislikeCount: json['dislikeCount'] ?? 0,
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
