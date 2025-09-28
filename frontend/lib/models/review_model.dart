// lib/models/review_model.dart

class Review {
  final String recipeName;
  final String title;
  final String content;
  final String? imageUrl;
  int views = 0; // 조회수
  int likes = 0; // 좋아요 수
  bool isLiked = false;

  Review({
    required this.recipeName,
    required this.title,
    required this.content,
    this.imageUrl,
  });
}
