// lib/models/recipe_model.dart

enum ReactionState { none, liked, disliked }

class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final bool isCustom;
  final List<String> instructions;
  int likes;
  ReactionState userReaction;
  final String imageAssetPath;
  final String cookingTime;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.isCustom,
    required this.instructions,
    this.likes = 0,
    this.userReaction = ReactionState.none,
    required this.imageAssetPath,
    required this.cookingTime,
  });
}
