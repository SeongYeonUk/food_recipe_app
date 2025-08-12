// lib/screens/ingredient_management_screen.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ingredient_model.dart';

class IngredientManagementScreen extends StatefulWidget {
  final Ingredient? ingredient;

  const IngredientManagementScreen({super.key, this.ingredient});

  @override
  State<IngredientManagementScreen> createState() =>
      _IngredientManagementScreenState();
}

class _IngredientManagementScreenState extends State<IngredientManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late DateTime _selectedDate;
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.ingredient != null;

    if (_isEditMode) {
      _nameController = TextEditingController(text: widget.ingredient!.name);
      _quantityController =
          TextEditingController(text: widget.ingredient!.quantity);
      _selectedDate = widget.ingredient!.expiryDate;
    } else {
      _nameController = TextEditingController();
      _quantityController = TextEditingController();
      _selectedDate = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newIngredient = Ingredient(
        id: _isEditMode ? widget.ingredient!.id : DateTime.now().toString(),
        name: _nameController.text,
        quantity: _quantityController.text,
        expiryDate: _selectedDate,
        refrigeratorType:
        _isEditMode ? widget.ingredient!.refrigeratorType : '메인냉장고',
      );
      Navigator.of(context).pop(newIngredient);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 테마의 색상들을 가져옵니다.
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '식재료 수정' : '식재료 추가'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '식재료 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: '수량 (예: 3개, 500ml, 1봉지)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '수량을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('유통기한', style: TextStyle(fontSize: 16)),
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    // AppTheme.accentColor 대신 현재 테마의 secondary 색상을 사용
                    style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary),
                    child: const Text('날짜 선택',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveForm,
                // AppTheme.primaryColor 대신 현재 테마의 primary 색상을 사용
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  '저장',
                  style: TextStyle(
                      fontSize: 18, color: colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

