// lib/models/community_post_model.dart

enum PostType { showcase, review }

// '레시피 자랑'과 '레시피 후기' 게시물 데이터를 모두 담을 수 있는 통합 모델
class CommunityPost {
  final int id;
  final PostType type;
  final String title;
  final String imageUrl;
  final String recipeName;
  final int likes;
  final int views;
  final int comments;

  CommunityPost({
    required this.id,
    required this.type,
    required this.title,
    required this.imageUrl,
    this.recipeName = '',
    this.likes = 0,
    this.views = 0,
    this.comments = 0,
  });
}
