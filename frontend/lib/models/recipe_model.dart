// lib/models/recipe_model.dart

enum ReactionState { none, liked, disliked }

class Recipe {
  final int id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String cookingTime;
  final String imageUrl;
  final bool isCustom;
  final String authorNickname;
  ReactionState userReaction;
  int likes;
  bool isFavorite;
  bool isHidden;

  // Nutrition / price totals (nullable if 서버 계산 안 됨)
  final double? totalKcal;
  final double? totalCarbsG;
  final double? totalProteinG;
  final double? totalFatG;
  final double? totalSodiumMg;
  final double? estimatedMinPriceKrw;
  final double? estimatedMaxPriceKrw;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.cookingTime,
    required this.imageUrl,
    required this.isCustom,
    required this.authorNickname,
    this.userReaction = ReactionState.none,
    this.likes = 0,
    required this.isFavorite,
    this.isHidden = false,
    this.totalKcal,
    this.totalCarbsG,
    this.totalProteinG,
    this.totalFatG,
    this.totalSodiumMg,
    this.estimatedMinPriceKrw,
    this.estimatedMaxPriceKrw,
  });

  // 👇👇👇 이 생성자를 여기에 추가해주세요! 👇👇👇
  // orElse를 위한 기본 생성자입니다.
  Recipe.basic({required this.id, required this.name, required this.likes})
    : description = '',
      ingredients = [],
      instructions = [],
      cookingTime = '0분',
      imageUrl = '',
      isCustom = false,
      authorNickname = 'AI',
      userReaction = ReactionState.none,
      isFavorite = false,
      isHidden = false,
      totalKcal = null,
      totalCarbsG = null,
      totalProteinG = null,
      totalFatG = null,
      totalSodiumMg = null,
      estimatedMinPriceKrw = null,
      estimatedMaxPriceKrw = null;
  // 🔼🔼🔼 여기까지 추가 🔼🔼🔼

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
      description: json['description'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      cookingTime: json['cookingTime'] ?? '0분',
      imageUrl: json['imageUrl'] ?? '',
      isCustom: json['custom'] ?? false,
      authorNickname: json['user']?['nickname'] ?? 'AI',
      likes: json['likeCount'] ?? 0,
      userReaction: reaction,
      isFavorite: json['favorite'] ?? json['isFavorite'] ?? false,
      totalKcal: _toDouble(json['totalKcal']),
      totalCarbsG: _toDouble(json['totalCarbsG']),
      totalProteinG: _toDouble(json['totalProteinG']),
      totalFatG: _toDouble(json['totalFatG']),
      totalSodiumMg: _toDouble(json['totalSodiumMg']),
      estimatedMinPriceKrw: _toDouble(json['estimatedMinPriceKrw']),
      estimatedMaxPriceKrw: _toDouble(json['estimatedMaxPriceKrw']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
