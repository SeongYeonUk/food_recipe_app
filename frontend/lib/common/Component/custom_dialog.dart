// lib/widgets/ingredient_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:food_recipe_app/models/ingredient_model.dart';
import 'package:food_recipe_app/models/refrigerator_model.dart';
import 'package:food_recipe_app/viewmodels/refrigerator_viewmodel.dart';

class IngredientFormDialog extends StatefulWidget {
  final Ingredient? ingredient;
  final int initialRefrigeratorId;
  final String? initialName;

  // [수정] 두 개의 생성자를 하나로 병합했습니다.
  const IngredientFormDialog({
    super.key,
    this.ingredient,
    required this.initialRefrigeratorId,
    this.initialName,
  });

  @override
  State<IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late int _selectedRefrigeratorId;
  late bool _isEditMode;

  final List<String> _categories = [
    '채소',
    '과일',
    '육류',
    '어패류',
    '유제품',
    '가공식품',
    '음료',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.ingredient != null;

    if (_isEditMode) {
      final ing = widget.ingredient!;
      _nameController = TextEditingController(text: ing.name);
      _quantityController = TextEditingController(
        text: ing.quantity.toString(),
      );
      _selectedDate = ing.expiryDate;
      _selectedCategory = ing.category;
      _selectedRefrigeratorId = ing.refrigeratorId;
    } else {
      _nameController = TextEditingController(text: widget.initialName ?? '');
      _quantityController = TextEditingController();
      _selectedDate = DateTime.now().add(const Duration(days: 7));
      _selectedCategory = _categories.first;
      _selectedRefrigeratorId = widget.initialRefrigeratorId;
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
        id: _isEditMode ? widget.ingredient!.id : 0,
        name: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text),
        expiryDate: _selectedDate,
        registrationDate: _isEditMode
            ? widget.ingredient!.registrationDate
            : DateTime.now(),
        category: _selectedCategory,
        refrigeratorId: _selectedRefrigeratorId,
      );
      Navigator.of(context).pop(newIngredient);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refrigerators = Provider.of<RefrigeratorViewModel>(
      context,
      listen: false,
    ).refrigerators;

    return AlertDialog(
      title: Text(_isEditMode ? '식재료 수정' : '식재료 추가'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // [수정] 중복된 속성들(decoration, validator)을 제거했습니다.
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '식재료 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? '이름을 입력해주세요.'
                      : null,
                ),
                const SizedBox(height: 16),

                // [수정] 중복된 냉장고 선택 드롭다운 중 올바른 것 하나만 남겼습니다.
                DropdownButtonFormField<int>(
                  value: _selectedRefrigeratorId,
                  decoration: const InputDecoration(
                    labelText: '보관 장소 (냉장고)',
                    border: OutlineInputBorder(),
                  ),
                  items: refrigerators.map((Refrigerator fridge) {
                    return DropdownMenuItem<int>(
                      value: fridge.id,
                      child: Text(fridge.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRefrigeratorId = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // [수정] 중복된 속성들(decoration, items)을 제거했습니다.
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // [수정] 중복된 속성들(decoration, validator)을 제거했습니다.
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: '수량 (숫자만 입력)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      (value == null || value.isEmpty) ? '수량을 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),

                // [수정] 중복된 속성들(subtitle, trailing)을 제거했습니다.
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('유통기한'),
                  subtitle: Text(
                    DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(onPressed: _saveForm, child: const Text('저장')),
      ],
    );
  }
}
