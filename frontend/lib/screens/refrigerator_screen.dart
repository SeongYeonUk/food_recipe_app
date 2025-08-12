// lib/screens/refrigerator_screen.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

import '../models/ingredient_model.dart';
import 'ingredient_management_screen.dart';

class RefrigeratorScreen extends StatefulWidget {
  const RefrigeratorScreen({super.key});

  @override
  State<RefrigeratorScreen> createState() => _RefrigeratorScreenState();
}

class _RefrigeratorScreenState extends State<RefrigeratorScreen> {
  final List<String> _refrigeratorTypes = ['냉동실', '메인냉장고', '김치냉장고'];
  String _selectedRefrigerator = '메인냉장고';

  List<Ingredient> _allIngredients = [
    Ingredient(id: '1', name: '계란', expiryDate: DateTime(2025, 8, 10), quantity: '5개', refrigeratorType: '메인냉장고'),
    Ingredient(id: '2', name: '우유', expiryDate: DateTime(2025, 8, 1), quantity: '500ml', refrigeratorType: '메인냉장고'),
    Ingredient(id: '3', name: '양파', expiryDate: DateTime(2025, 8, 15), quantity: '2개', refrigeratorType: '메인냉장고'),
    Ingredient(id: '4', name: '냉동 만두', expiryDate: DateTime(2026, 1, 20), quantity: '1봉지', refrigeratorType: '냉동실'),
    Ingredient(id: '5', name: '배추김치', expiryDate: DateTime(2025, 10, 5), quantity: '1포기', refrigeratorType: '김치냉장고'),
  ];
  List<Ingredient> _filteredIngredients = [];

  @override
  void initState() {
    super.initState();
    _filterIngredients();
  }

  void _filterIngredients() {
    setState(() {
      _filteredIngredients = _allIngredients
          .where((i) => i.refrigeratorType == _selectedRefrigerator)
          .toList();
    });
  }

  Future<void> _navigateAndManageIngredient(Ingredient? ingredient) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            IngredientManagementScreen(ingredient: ingredient),
      ),
    );

    if (result != null && result is Ingredient) {
      setState(() {
        final index = _allIngredients.indexWhere((ing) => ing.id == result.id);
        if (index != -1) {
          _allIngredients[index] = result;
        } else {
          _allIngredients.add(result);
        }
        _filterIngredients();
      });
    }
  }

  void _deleteIngredient(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('식재료 삭제'),
        content: const Text('정말 이 식재료를 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(), child: const Text('아니오')),
          TextButton(
            onPressed: () {
              setState(() {
                _allIngredients.removeWhere((ing) => ing.id == id);
                _filterIngredients();
              });
              Navigator.of(ctx).pop();
            },
            child: Text('예', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 냉장고'),
      ),
      body: Column(
        children: [
          _buildRefrigeratorTabs(),
          const Divider(height: 1),
          Expanded(child: _buildIngredientList()),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildRefrigeratorTabs() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _refrigeratorTypes.length,
        itemBuilder: (context, index) {
          final type = _refrigeratorTypes[index];
          final isSelected = type == _selectedRefrigerator;
          return Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRefrigerator = type;
                  _filterIngredients();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                      isSelected ? colorScheme.primary : Colors.grey[300]!,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                    ]),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                      isSelected ? colorScheme.onPrimary : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIngredientList() {
    if (_filteredIngredients.isEmpty) {
      return Center(
          child: Text('텅 비었어요!\n식재료를 추가해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = _filteredIngredients[index];
        final formattedDate =
        DateFormat('yyyy-MM-dd').format(ingredient.expiryDate);

        return Card(
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text(ingredient.name,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle:
            Text('유통기한: $formattedDate / 수량: ${ingredient.quantity}'),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[700]),
              onPressed: () => _deleteIngredient(ingredient.id),
            ),
            onTap: () => _navigateAndManageIngredient(ingredient),
          ),
        );
      },
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.edit),
          label: '수동 입력',
          backgroundColor: Colors.white,
          onTap: () => _navigateAndManageIngredient(null),
        ),
        SpeedDialChild(
          child: const Icon(Icons.camera_alt_outlined),
          label: 'OCR (영수증)',
          backgroundColor: Colors.white,
          onTap: () {},
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: '바코드',
          backgroundColor: Colors.white,
          onTap: () {},
        ),
      ],
    );
  }
}



