// lib/models/ingredient_model.dart

class Ingredient {
  final String id;
  String name;
  DateTime expiryDate;
  String quantity;
  final String refrigeratorType; // '메인냉장고', '냉동실', '김치냉장고'

  Ingredient({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.quantity,
    required this.refrigeratorType,
  });
}
