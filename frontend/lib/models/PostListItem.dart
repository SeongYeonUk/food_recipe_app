class PostListItem {
  final int postId;
  final String title;
  final String? imageUrl; // (null일 수 있으므로 ? 추가)
  final String authorName;
  final int likeCount;
  final int reviewCount;

  PostListItem({
    required this.postId,
    required this.title,
    this.imageUrl,
    required this.authorName,
    required this.likeCount,
    required this.reviewCount,
  });

  // 서버에서 받은 JSON을 PostListItem 객체로 변환
  factory PostListItem.fromJson(Map<String, dynamic> json) {
    return PostListItem(
      postId: json['postId'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      authorName: json['authorName'],
      likeCount: json['likeCount'],
      reviewCount: json['reviewCount'],
    );
  }
}
