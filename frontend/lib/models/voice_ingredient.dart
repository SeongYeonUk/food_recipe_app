class VoiceIngredient {
  final String name;
  final int quantity;
  final String? unit;
  final String? category;
  final String? expirationDate;
  bool selected;

  VoiceIngredient({
    required this.name,
    required this.quantity,
    this.unit,
    this.category,
    this.expirationDate,
    this.selected = true,
  });

  factory VoiceIngredient.fromJson(Map<String, dynamic> json) {
    return VoiceIngredient(
      name: (json['name'] ?? '').toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      unit: json['unit']?.toString(),
      category: json['category']?.toString(),
      expirationDate: json['expirationDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'expirationDate': expirationDate,
    };
  }
}
