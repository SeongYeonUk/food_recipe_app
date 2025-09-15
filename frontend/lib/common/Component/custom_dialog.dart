// lib/widgets/ingredient_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ▼▼▼ [핵심 해결] 필요한 모델과 ViewModel 파일들을 import 합니다. ▼▼▼
import 'package:food_recipe_app/models/ingredient_model.dart';
import 'package:food_recipe_app/models/refrigerator_model.dart';
import 'package:food_recipe_app/viewmodels/refrigerator_viewmodel.dart';
// ▲▲▲ 여기까지 ▲▲▲

class IngredientFormDialog extends StatefulWidget {
  final Ingredient? ingredient;
  final int initialRefrigeratorId;

  const IngredientFormDialog({
    Key? key,
    this.ingredient,
    required this.initialRefrigeratorId,
  }) : super(key: key);

  @override
  _IngredientFormDialogState createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late int _selectedRefrigeratorId;
  late bool _isEditMode;

  final List<String> _categories = ['채소', '과일', '육류', '어패류', '유제품', '가공식품', '기타'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.ingredient != null;

    if (_isEditMode) {
      final ing = widget.ingredient!;
      _nameController = TextEditingController(text: ing.name);
      _quantityController = TextEditingController(text: ing.quantity.toString());
      _selectedDate = ing.expiryDate;
      _selectedCategory = ing.category;
      _selectedRefrigeratorId = ing.refrigeratorId;
    } else {
      _nameController = TextEditingController();
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
      setState(() { _selectedDate = picked; });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newIngredient = Ingredient(
        id: _isEditMode ? widget.ingredient!.id : 0,
        name: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text),
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
    // ViewModel에서 냉장고 목록을 가져옴
    final refrigerators = Provider.of<RefrigeratorViewModel>(context, listen: false).refrigerators;

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
                // 이제 import가 되었으므로 이 부분은 오류 없이 정상적으로 작동합니다.
                DropdownButtonFormField<int>(
                  value: _selectedRefrigeratorId,
                  decoration: const InputDecoration(labelText: '보관 장소 (냉장고)', border: OutlineInputBorder()),
                  items: refrigerators.map((Refrigerator fridge) {
                    return DropdownMenuItem<int>(
                      value: fridge.id,
                      child: Text(fridge.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() { _selectedRefrigeratorId = newValue; });
                    }
                  },
                ),
                const SizedBox(height: 16),
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
                ),
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
                  trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context)),
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
