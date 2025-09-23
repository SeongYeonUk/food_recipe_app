// lib/models/recipe_model.dart

enum ReactionState { none, liked, disliked }

class Recipe {
  final int id;
  final String name;
  final String description; // [솔루션] description 필드 부활
  final List<String> ingredients;
  final List<String> instructions;
  final String cookingTime;
  final String imageUrl;
  final bool isCustom;
  final String authorNickname;
  ReactionState userReaction;
  int likes;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.name,
    required this.description, // 생성자에 추가
    required this.ingredients,
    required this.instructions,
    required this.cookingTime,
    required this.imageUrl,
    required this.isCustom,
    required this.authorNickname,
    this.userReaction = ReactionState.none,
    this.likes = 0,
    required this.isFavorite,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    ReactionState reaction = ReactionState.none;
    switch (json['userReaction']) {
      case 'liked':
        reaction = ReactionState.liked;
        break;
      case 'disliked':
        reaction = ReactionState.disliked;
        break;
    }

    return Recipe(
      id: json['recipeId'] ?? 0,
      name: json['recipeName'] ?? '이름 없음',
      description: json['description'] ?? '', // [솔루션] fromJson에 추가
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      cookingTime: json['cookingTime'] ?? '0분',
      imageUrl: json['imageUrl'] ?? '',
      isCustom: json['custom'] ?? false,
      authorNickname: json['user']?['nickname'] ?? 'AI',
      likes: json['likeCount'] ?? 0,
      userReaction: reaction,
      isFavorite: json['favorite'] ?? false,
    );
  }
}




