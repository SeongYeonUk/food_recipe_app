import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/allergy_viewmodel.dart';

class AllergyIngredientScreen extends StatefulWidget {
  const AllergyIngredientScreen({super.key});

  @override
  State<AllergyIngredientScreen> createState() => _AllergyIngredientScreenState();
}

class _AllergyIngredientScreenState extends State<AllergyIngredientScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AllergyViewModel>().loadAllergies());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addAllergy(AllergyViewModel viewModel) async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추가할 식재료 이름을 입력해 주세요.')),
      );
      return;
    }
    try {
      await viewModel.addAllergy(name);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\'$name\' 이(가) 알레르기 목록에 추가되었어요.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      final message = viewModel.errorMessage ?? '추가 중 문제가 발생했어요.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteAllergy(AllergyViewModel viewModel, int id, String name) async {
    try {
      await viewModel.deleteAllergy(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\'$name\' 알레르기 식재료가 삭제되었어요.')),
      );
    } catch (_) {
      if (!mounted) return;
      final message = viewModel.errorMessage ?? '삭제 중 문제가 발생했어요.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알레르기 식재료 관리'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<AllergyViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '알레르기가 있는 식재료를 등록하면\n해당 재료가 포함된 레시피는 추천 목록에서 자동으로 제외돼요.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: '알레르기 식재료',
                    hintText: '예) 땅콩, 우유',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => _addAllergy(viewModel),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: viewModel.isLoading ? null : () => _addAllergy(viewModel),
                    icon: const Icon(Icons.add),
                    label: const Text('추가하기'),
                  ),
                ),
                const SizedBox(height: 12),
                if (viewModel.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (viewModel.items.isEmpty)
                  const Expanded(
                    child: Center(child: Text('등록된 알레르기 식재료가 없어요.')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: viewModel.items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = viewModel.items[index];
                        return ListTile(
                          title: Text(item.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteAllergy(viewModel, item.id, item.name),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
