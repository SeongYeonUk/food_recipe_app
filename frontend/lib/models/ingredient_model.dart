// lib/models/ingredient_model.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Refrigerator {
  final int id;
  final String name;
  String currentImage;
  final List<String> availableImages;

  Refrigerator({
    required this.id,
    required this.name,
    required this.currentImage,
    required this.availableImages,
  });

  // 수정 한 부분
  // 서버에서 받은 JSON 데이터를 Refrigerator 객체로 변환하는 factory 생성자
  factory Refrigerator.fromJson(Map<String, dynamic> json) {
    String type = json['type']; // 서버에서는 "MAIN", "FREEZER", "KIMCHI" 등으로 옴
    String name;
    String currentImage;
    List<String> availableImages;

    // 서버에서 받은 type 값에 따라 화면에 표시될 이름과 이미지 경로를 지정합니다.
    switch (type) {
      case '냉동실':
        name = '냉동실';
        currentImage = 'asset/img/Refrigerator/냉동실1.png';
        availableImages = [
          'asset/img/Refrigerator/냉동실1.png',
          'asset/img/Refrigerator/냉동실2.png',
          'asset/img/Refrigerator/냉동실3.png',
        ];
        break;
      case '김치냉장고':
        name = '김치냉장고';
        currentImage = 'asset/img/Refrigerator/김치냉장고1.png';
        availableImages = [
          'asset/img/Refrigerator/김치냉장고1.png',
          'asset/img/Refrigerator/김치냉장고2.png',
        ];
        break;
      case '메인냉장고':
      default: // 기본값
        name = '메인냉장고';
        currentImage = 'asset/img/Refrigerator/냉장고1.png';
        availableImages = [
          'asset/img/Refrigerator/냉장고1.png',
          'asset/img/Refrigerator/냉장고2.png',
          'asset/img/Refrigerator/냉장고3.png',
          'asset/img/Refrigerator/냉장고4.png',
        ];
        break;
    }

    return Refrigerator(
      id: json['refrigeratorId'], // 서버 응답 JSON의 필드명인 'refrigeratorId'를 사용
      name: name,
      currentImage: currentImage,
      availableImages: availableImages,
    );
  }
}

class Ingredient {
  final int id; // Dialog 코드와 호환을 위해 non-nullable int 유지
  String name;
  DateTime expiryDate;
  int quantity;
  final DateTime registrationDate;
  String category;
  String refrigeratorType;

  Ingredient({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.quantity,
    required this.registrationDate,
    required this.category,
    required this.refrigeratorType,
  });

  int get dDay => expiryDate.difference(DateTime.now()).inDays;
  String get dDayText => (dDay < 0) ? 'D+${-dDay}' : 'D-$dDay';
  Color get dDayColor {
    if (dDay < 0) return Colors.grey.shade700;
    if (dDay <= 3) return Colors.red.shade700;
    if (dDay <= 7) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  // 서버 응답(JSON)으로부터 Ingredient 객체를 생성하는 factory 생성자
  factory Ingredient.fromJson(
    Map<String, dynamic> json,
    String refrigeratorType,
  ) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      expiryDate: DateTime.parse(json['expiryDate']),
      registrationDate: DateTime.parse(json['registrationDate']),
      category: json['category'],
      refrigeratorType: refrigeratorType,
    );
  }

  // 서버 요청을 위해 Ingredient 객체를 JSON으로 변환하는 메소드
  Map<String, dynamic> toJson() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return {
      // id는 서버 요청 시 보내지 않음 (Create 시)
      'name': name,
      'quantity': quantity,
      'expiryDate': formatter.format(expiryDate),
      'registrationDate': formatter.format(registrationDate),
      'category': category,
    };
  }
}
