// lib/models/ingredient_model.dart

import 'package:flutter/material.dart';

class Refrigerator {
  final String name;
  final List<String> availableImages;
  String currentImage;

  Refrigerator({
    required this.name,
    required this.availableImages,
    required this.currentImage,
  });
}

class Ingredient {
  final int id;
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

  int get dDay => expiryDate.difference(DateTime.now()).inDays + 1;
  String get dDayText => (dDay <= 0) ? 'D-Day' : 'D-$dDay';
  Color get dDayColor {
    if (dDay <= 0) return Colors.red.shade700;
    if (dDay <= 3) return Colors.orange.shade700;
    return Colors.green.shade700;
  }
}