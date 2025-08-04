import 'package:flutter/material.dart';

class IngredientManagementScreen extends StatefulWidget {
  const IngredientManagementScreen({super.key});

  @override
  _IngredientManagementScreenState createState() => _IngredientManagementScreenState();
}

class _IngredientManagementScreenState extends State<IngredientManagementScreen> {
  // 샘플 데이터
  final List<Map<String, String>> _ingredients = [
    {'name': '계란', 'expiry': '2025-08-10', 'quantity': '5개'},
    {'name': '우유', 'expiry': '2025-08-01', 'quantity': '500ml'},
    {'name': '양파', 'expiry': '2025-08-15', 'quantity': '2개'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 냉장고'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: 필터 기능 구현 (이름순, 유통기한순 등)
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _ingredients.length,
        itemBuilder: (context, index) {
          final item = _ingredients[index];
          return ListTile(
            title: Text(item['name']!),
            subtitle: Text('유통기한: ${item['expiry']} / 수량: ${item['quantity']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  _ingredients.removeAt(index);
                });
                // TODO: 백엔드에 삭제 요청
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 식재료 추가 기능 구현 (바코드, OCR, 수동 입력 등)
          // 예시: 간단한 다이얼로그로 추가
          _showAddIngredientDialog();
        },
        child: const Icon(Icons.add),
        tooltip: '식재료 추가',
      ),
    );
  }

  void _showAddIngredientDialog() {
    // 다이얼로그 UI 및 로직 구현
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('식재료 추가'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(decoration: InputDecoration(labelText: '식재료명')),
                TextField(decoration: InputDecoration(labelText: '유통기한')),
                TextField(decoration: InputDecoration(labelText: '수량')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              ElevatedButton(onPressed: () {
                // TODO: 입력된 정보로 식재료 추가 로직
                Navigator.pop(context);
              }, child: const Text('추가')),
            ],
          );
        });
  }
}
