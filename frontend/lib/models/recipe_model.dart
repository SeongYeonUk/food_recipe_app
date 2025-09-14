// lib/models/recipe_model.dart

// 좋아요/싫어요/없음 상태를 나타내는 Enum
enum ReactionState { none, liked, disliked }

class Recipe {
  final int id;         // [수정] String -> int
  final String name;
  final List<String> ingredients;
  final bool isCustom;
  final List<String> instructions;
  int likes;
  ReactionState userReaction;
  final String imageUrl;    // [이름 변경] imageAssetPath -> imageUrl
  final int cookingTime; // [수정] String -> int. 예: 30

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.isCustom,
    required this.instructions,
    this.likes = 0,
    this.userReaction = ReactionState.none,
    required this.imageUrl,
    required this.cookingTime,
  });

  // [핵심 추가] 서버에서 받은 JSON 데이터로부터 Recipe 객체를 생성하는 factory 생성자
  factory Recipe.fromJson(Map<String, dynamic> json) {
    // 서버에서 주는 reaction 문자열(String)을 ReactionState(enum)으로 변환
    ReactionState reaction = ReactionState.none;
    switch(json['userReaction']) { // 이 필드 이름은 백엔드와 합의 필요
      case 'liked':
        reaction = ReactionState.liked;
        break;
      case 'disliked':
        reaction = ReactionState.disliked;
        break;
    }

    // 백엔드에서 ingredients, instructions를 단일 String으로 줄 경우를 대비한 안전장치
    List<String> ingredientsList = (json['ingredients'] is List)
        ? List<String>.from(json['ingredients'])
        : (json['ingredients'] as String? ?? '').split('\n');

    List<String> instructionsList = (json['instructions'] is List)
        ? List<String>.from(json['instructions'])
        : (json['instructions'] as String? ?? '').split('\n');

    return Recipe(
      // 백엔드 DTO의 필드 이름('title', 'time' 등)에 정확히 맞춰줌
      id: json['recipeId'] ?? json['id'], // 'recipeId' 또는 'id' 키로 ID를 받음
      name: json['title'] ?? '이름 없음',
      ingredients: ingredientsList,
      instructions: instructionsList,
      likes: json['likes'] ?? 0,
      cookingTime: json['time'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      isCustom: json['custom'] ?? false, // 'custom' 이라는 키로 boolean 값을 받는다고 가정
      userReaction: reaction,
    );
  }
}

