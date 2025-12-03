class BasicRecipeItem {
  final String recipeId;
  final String recipeNameKo;
  final String summary;
  final String cookingTime;
  final String levelName;
  final String calorie;
  final String imageUrl;
  final double? maxPriceKrw;

  BasicRecipeItem({
    required this.recipeId,
    required this.recipeNameKo,
    required this.summary,
    required this.cookingTime,
    required this.levelName,
    required this.calorie,
    required this.imageUrl,
    this.maxPriceKrw,
  });

  factory BasicRecipeItem.fromJson(Map<String, dynamic> json) {
    return BasicRecipeItem(
      recipeId: (json['RECIPE_ID'] ?? json['recipeId'])?.toString() ?? 'ID 없음',
      recipeNameKo: (json['RECIPE_NM_KO'] ?? json['recipeNameKo'])?.toString() ?? '이름 없음',
      summary: (json['SUMRY'] ?? json['summary'])?.toString() ?? '요약 없음',
      cookingTime: (json['COOKING_TIME'] ?? json['cookingTime'])?.toString() ?? '',
      levelName: (json['LEVEL_NM'] ?? json['levelName'])?.toString() ?? '',
      calorie: (json['CALORIE'] ?? json['calorie'])?.toString() ?? '',
      imageUrl: (json['IMG_URL'] ?? json['imageUrl'])?.toString() ?? '',
      maxPriceKrw: _toDouble(
        json['estimated_max_price_krw'] ??
            json['estimatedMaxPriceKrw'] ??
            json['ESTIMATED_MAX_PRICE_KRW'] ??
            json['maxPriceKrw'] ??
            json['max_price_krw'] ??
            json['MAX_PRICE_KRW'] ??
            json['MAX_PRICE'] ??
            json['max_price'] ??
            json['PRICE'] ??
            json['price'] ??
            json['priceName'] ??
            json['PC_NM'],
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').replaceAll('원', '').trim();
      return double.tryParse(cleaned);
    }
    return null;
  }
}
