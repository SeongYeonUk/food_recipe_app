// lib/models/statistics_model.dart

// 인기 레시피 모델
class PopularRecipe {
  final String id;
  final String name;
  final String ingredientsPreview; 
  final int likes;

  PopularRecipe({
    required this.id,
    required this.name,
    required this.ingredientsPreview,
    required this.likes,
  });
}


class PopularIngredient {
  final String name;
  final int count;
  final String coupangUrl;

  PopularIngredient({
    required this.name,
    required this.count,
    required this.coupangUrl,
  });
}
