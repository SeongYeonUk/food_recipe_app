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

  // ▼▼▼ [핵심 수정] ViewModel로부터 카테고리 목록을 받아올 변수 ▼▼▼
  late List<String> _categories;
  // ▲▲▲ 여기까지 ▲▲▲

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.ingredient != null;

    // ▼▼▼ [핵심 수정] ViewModel에서 카테고리 목록을 가져옴 ▼▼▼
    final viewModel = Provider.of<RefrigeratorViewModel>(context, listen: false);
    // ViewModel에 카테고리가 없으면, 기본 목록을 임시로 사용
    _categories = viewModel.categories.isNotEmpty ? viewModel.categories : ['채소', '과일', '육류', '기타'];
    // ▲▲▲ 여기까지 ▲▲▲

    if (_isEditMode) {
      final ing = widget.ingredient!;
      _nameController = TextEditingController(text: ing.name);
      _quantityController = TextEditingController(text: ing.quantity.toString());
      _selectedDate = ing.expiryDate;
      _selectedCategory = ing.category;
      // 수정 모드일 때, ViewModel에 없는 카테고리라면 목록에 임시로 추가
      if (!_categories.contains(_selectedCategory)) {
        _categories.add(_selectedCategory);
      }
      _selectedRefrigeratorId = ing.refrigeratorId;
    } else {
      _nameController = TextEditingController(text: widget.initialName ?? '');
      _quantityController = TextEditingController(text: '1'); // 기본값 1로 설정
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
        quantity: int.tryParse(_quantityController.text) ?? 1, // 파싱 실패 시 기본값 1
        expiryDate: _selectedDate,
        registrationDate: _isEditMode ? widget.ingredient!.registrationDate : DateTime.now(),
        category: _selectedCategory,
        refrigeratorId: _selectedRefrigeratorId,
      );
      Navigator.of(context).pop(newIngredient);
    }
  }

  @override
  Widget build(BuildContext context) {
    // [수정] listen: false는 initState에서만 사용하고, 여기서는 Provider.of를 한번만 호출
    final viewModel = Provider.of<RefrigeratorViewModel>(context, listen: false);

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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '식재료 이름', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? '이름을 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedRefrigeratorId,
                  decoration: const InputDecoration(labelText: '보관 장소 (냉장고)', border: OutlineInputBorder()),
                  items: viewModel.refrigerators.map((Refrigerator fridge) {
                    return DropdownMenuItem<int>(value: fridge.id, child: Text(fridge.name));
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() { _selectedRefrigeratorId = newValue; });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // ▼▼▼ [핵심 수정] 카테고리 드롭다운이 _categories 변수를 사용하도록 변경 ▼▼▼
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() { _selectedCategory = newValue; });
                    }
                  },
                  // 카테고리 직접 입력을 위한 기능 (선택 사항)
                  // onSaved: (value) => _selectedCategory = value ?? _categories.first,
                ),
                // ▲▲▲ 여기까지 ▲▲▲
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: '수량 (숫자만 입력)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty) ? '수량을 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('유통기한'),
                  subtitle: Text(DateFormat('yyyy년 MM월 dd일').format(_selectedDate)),
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
        ElevatedButton(onPressed: _saveForm, child: const Text('저장')),
      ],
    );
  }
}

