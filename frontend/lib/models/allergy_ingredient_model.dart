class AllergyIngredientModel {
  final int id;
  final int? ingredientId;
  final String name;

  AllergyIngredientModel({
    required this.id,
    required this.name,
    this.ingredientId,
  });

  factory AllergyIngredientModel.fromJson(Map<String, dynamic> json) {
    return AllergyIngredientModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      ingredientId: json['ingredientId'] == null
          ? null
          : (json['ingredientId'] is int ? json['ingredientId'] : int.tryParse(json['ingredientId'].toString())),
      name: json['name'] ?? '',
    );
  }
}
