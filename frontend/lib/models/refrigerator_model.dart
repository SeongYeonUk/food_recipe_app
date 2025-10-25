// lib/models/refrigerator_model.dart

enum RefrigeratorType {
  main,
  freezer,
  kimchi,
  unknown,
}

class Refrigerator {
  final int id;
  final RefrigeratorType type;
  final String name;
  String currentImage;
  final List<String> availableImages;

  Refrigerator({
    required this.id,
    required this.type,
    required this.name,
    required this.currentImage,
    required this.availableImages,
  });

  factory Refrigerator.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['refrigeratorId'] is int) {
      parsedId = json['refrigeratorId'];
    } else if (json['refrigeratorId'] is String) {
      parsedId = int.tryParse(json['refrigeratorId']) ?? 0;
    }

    String serverType = json['type'];
    RefrigeratorType type;
    String name;
    String currentImage;
    List<String> availableImages;

    switch (serverType) {
      case '냉동실':
        type = RefrigeratorType.freezer;
        name = '냉동실';
        currentImage = 'asset/img/Refrigerator/냉동실1.png';
        availableImages = ['asset/img/Refrigerator/냉동실1.png', 'asset/img/Refrigerator/냉동실2.png', 'asset/img/Refrigerator/냉동실3.png'];
        break;
      case '김치냉장고':
        type = RefrigeratorType.kimchi;
        name = '김치냉장고';
        currentImage = 'asset/img/Refrigerator/김치냉장고1.png';
        availableImages = ['asset/img/Refrigerator/김치냉장고1.png', 'asset/img/Refrigerator/김치냉장고2.png'];
        break;
      case '냉장고':
      default:
        type = RefrigeratorType.main;
        name = '메인냉장고';
        currentImage = 'asset/img/Refrigerator/냉장고1.png';
        availableImages = ['asset/img/Refrigerator/냉장고1.png', 'asset/img/Refrigerator/냉장고2.png', 'asset/img/Refrigerator/냉장고3.png', 'asset/img/Refrigerator/냉장고4.png'];
        break;
    }

    return Refrigerator(
      id: parsedId,
      type: type,
      name: name,
      currentImage: currentImage,
      availableImages: availableImages,
    );
  }
}
