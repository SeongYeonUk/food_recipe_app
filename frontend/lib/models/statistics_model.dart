// lib/models/statistics_model.dart

// 인기 식재료 모델 (이 클래스는 그대로 사용합니다)
class PopularIngredient {
  final String name;
  final int count; // 전체 사용자 등록 횟수
  final String coupangUrl; // 쿠팡 검색 링크

  PopularIngredient({
    required this.name,
    required this.count,
    required this.coupangUrl,
  });
}

// PopularRecipe 클래스는 Recipe 모델을 직접 사용하기로 했으므로 삭제합니다.

