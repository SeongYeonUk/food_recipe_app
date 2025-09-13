class OffResult {
  final String code;
  final String name;        // 입력창에는 이 값을 우선 사용
  final String? brand;
  final String? quantity;
  final String? imageUrl;

  OffResult({
    required this.code,
    required this.name,
    this.brand,
    this.quantity,
    this.imageUrl,
  });

  factory OffResult.fromJson(Map<String, dynamic> json) {
    return OffResult(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      brand: json['brand'] as String?,
      quantity: json['quantity'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
