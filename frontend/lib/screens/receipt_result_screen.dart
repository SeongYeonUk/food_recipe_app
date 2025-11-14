import 'package:flutter/material.dart';
import 'package:food_recipe_app/models/ingredient_model.dart';
import 'package:food_recipe_app/viewmodels/refrigerator_viewmodel.dart';
import 'package:food_recipe_app/common/Component/custom_dialog.dart';
import 'package:provider/provider.dart';

class ReceiptResultScreen extends StatefulWidget {
  const ReceiptResultScreen({Key? key}) : super(key: key);

  @override
  _ReceiptResultScreenState createState() => _ReceiptResultScreenState();
}

class _ReceiptResultScreenState extends State<ReceiptResultScreen> {

  // 개별 식재료 수정 다이얼로그 표시
  Future<void> _editIngredient(BuildContext context, RefrigeratorViewModel viewModel, int index) async {
    final originalIngredient = viewModel.scannedIngredients[index];
    final refrigerators = viewModel.refrigerators;

    if (refrigerators.isEmpty) return;

    final result = await showDialog<Ingredient>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => IngredientFormDialog(
        ingredient: originalIngredient,
        initialRefrigeratorId: originalIngredient.refrigeratorId,
      ),
    );

    if (result != null) {
      setState(() {
        viewModel.scannedIngredients[index] = result;
      });
    }
  }

  // 전체 저장 로직
  void _saveAll(BuildContext context, RefrigeratorViewModel viewModel) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 저장할 아이템이 없는 경우
    if (viewModel.scannedIngredients.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('저장할 식재료가 없습니다.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final success = await viewModel.addAllScannedIngredients();

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('식재료가 성공적으로 추가되었습니다.'), backgroundColor: Colors.green),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('일부 식재료 추가에 실패했습니다.'), backgroundColor: Colors.red),
      );
    }
    navigator.pop(); // 저장 후 이전 화면으로 돌아가기
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RefrigeratorViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: null,
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => _saveAll(context, viewModel),
                tooltip: '모두 저장',
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '아래 목록을 확인하고 수정해주세요.\n불필요한 항목은 왼쪽으로 밀어서 삭제할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                // ▲▲
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.scannedIngredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = viewModel.scannedIngredients[index];
                    return Dismissible(
                      key: ValueKey(ingredient.name + index.toString()), // 고유 키
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() {
                          viewModel.scannedIngredients.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("'${ingredient.name}' 항목을 삭제했습니다.")),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_forever, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('수량: ${ingredient.quantity} | 카테고리: ${ingredient.category}'),
                          trailing: const Icon(Icons.edit_outlined),
                          onTap: () => _editIngredient(context, viewModel, index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('선택한 식재료 모두 저장하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _saveAll(context, viewModel),
            ),
          ),
        );
      },
    );
  }
}
