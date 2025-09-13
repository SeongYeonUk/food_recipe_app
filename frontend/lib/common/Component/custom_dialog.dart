import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/ingredient_model.dart';

class IngredientFormDialog extends StatefulWidget {
  final Ingredient? ingredient;
  final String? initialRefrigeratorType;

  // ↓↓↓ 바코드 스캔 결과로 받아온 이름을 프리필하기 위한 옵션 파라미터
  final String? initialName;

  const IngredientFormDialog({
    super.key,
    this.ingredient,
    this.initialRefrigeratorType,
    this.initialName, // ← NEW
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
  late String _selectedRefrigerator;
  late bool _isEditMode;

  final List<String> _categories = ['채소', '과일', '육류', '어패류', '유제품', '가공식품', '기타'];
  final List<String> _refrigeratorTypes = ['메인냉장고', '냉동실', '김치냉장고'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.ingredient != null;

    if (_isEditMode) {
      _nameController = TextEditingController(text: widget.ingredient!.name);
      _quantityController =
          TextEditingController(text: widget.ingredient!.quantity.toString());
      _selectedDate = widget.ingredient!.expiryDate;
      _selectedCategory = widget.ingredient!.category;
      _selectedRefrigerator = widget.ingredient!.refrigeratorType;
    } else {
      // ← NEW: 바코드 경로에서 넘어온 initialName을 우선 적용
      _nameController = TextEditingController(text: widget.initialName ?? '');
      _quantityController = TextEditingController();
      _selectedDate = DateTime.now().add(const Duration(days: 7));
      _selectedCategory = _categories.first;
      _selectedRefrigerator =
          widget.initialRefrigeratorType ?? _refrigeratorTypes.first;
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
        id: _isEditMode
            ? widget.ingredient!.id
            : DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text,
        quantity: int.parse(_quantityController.text),
        expiryDate: _selectedDate,
        registrationDate:
        _isEditMode ? widget.ingredient!.registrationDate : DateTime.now(),
        category: _selectedCategory,
        refrigeratorType: _selectedRefrigerator,
      );
      Navigator.of(context).pop(newIngredient);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: const InputDecoration(
                    labelText: '식재료 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? '이름을 입력해주세요.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRefrigerator,
                  decoration: const InputDecoration(
                    labelText: '보관 장소 (냉장고)',
                    border: OutlineInputBorder(),
                  ),
                  items: _refrigeratorTypes
                      .map((String type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedRefrigerator = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((String category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('유통기한'),
                  subtitle:
                  Text(DateFormat('yyyy년 MM월 dd일').format(_selectedDate)),
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
        ElevatedButton(
          onPressed: _saveForm,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
