class BasicRecipeItem {
  final String recipeId;
  final String recipeNameKo;
  final String summary;
  final String cookingTime;
  final String levelName;
  final String calorie;
  final String imageUrl;

  BasicRecipeItem({
    required this.recipeId,
    required this.recipeNameKo,
    required this.summary,
    required this.cookingTime,
    required this.levelName,
    required this.calorie,
    required this.imageUrl,
  });

  // JSON 데이터를 BasicRecipeItem 객체로 변환해주는 똑똑한 생성자
  factory BasicRecipeItem.fromJson(Map<String, dynamic> json) {
    return BasicRecipeItem(
      recipeId: json['RECIPE_ID'] ?? 'ID 없음',
      recipeNameKo: json['RECIPE_NM_KO'] ?? '이름 없음',
      summary: json['SUMRY'] ?? '요약 없음',
      cookingTime: json['COOKING_TIME'] ?? '',
      levelName: json['LEVEL_NM'] ?? '',
      calorie: json['CALORIE'] ?? '',
      imageUrl: json['IMG_URL'] ?? '', // 이미지가 없을 경우를 대비
    );
  }
}
