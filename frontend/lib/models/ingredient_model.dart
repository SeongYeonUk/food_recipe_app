// lib/models/ingredient_model.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Ingredient {
  final int id;
  String name;
  DateTime expiryDate;
  int quantity;
  final DateTime registrationDate;
  String category;
  int refrigeratorId;
  int iconIndex; // category-specific icon variant index

  Ingredient({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.quantity,
    required this.registrationDate,
    required this.category,
    required this.refrigeratorId,
    this.iconIndex = 0,
  });

  // [수정 완료] DateTime.now()로 올바르게 수정했습니다.
  int get dDay => expiryDate.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
  String get dDayText => (dDay < 0) ? 'D+${-dDay}' : 'D-$dDay';
  Color get dDayColor {
    if (dDay < 0) return Colors.grey.shade700;
    if (dDay <= 3) return Colors.red.shade700;
    if (dDay <= 7) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  factory Ingredient.fromJson(Map<String, dynamic> json, int refrigeratorId) {
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] is String) {
      parsedId = int.tryParse(json['id']) ?? 0;
    }

    return Ingredient(
      id: parsedId,
      name: json['name'],
      quantity: json['quantity'],
      expiryDate: DateTime.parse(json['expiryDate']),
      registrationDate: DateTime.parse(json['registrationDate']),
      category: json['category'],
      refrigeratorId: refrigeratorId,
      iconIndex: (json['iconIndex'] is int)
          ? json['iconIndex']
          : int.tryParse(json['iconIndex']?.toString() ?? '') ?? 0,
    );
  }

  // 이 toJson() 메소드는 백엔드의 ItemCreateRequestDto와 완벽하게 일치합니다.
  Map<String, dynamic> toJson() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return {
      'name': name,
      'quantity': quantity,
      'expiryDate': formatter.format(expiryDate),
      'registrationDate': formatter.format(DateTime.now()),
      'category': category,
      'iconIndex': iconIndex,
    };
  }
}
