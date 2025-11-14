// lib/screens/create_recipe_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/recipe_viewmodel.dart';
import '../models/ingredient_input_model.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});
  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController(); // [솔루션] 컨트롤러 부활
  final _instructionsController = TextEditingController();
  final _timeController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  List<IngredientInputModel> _ingredientInputs = [];

  @override
  void initState() {
    super.initState();
    _addIngredientInput();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose(); // dispose에 추가
    _instructionsController.dispose();
    _timeController.dispose();
    for (var input in _ingredientInputs) {
      input.nameController.dispose();
      input.amountController.dispose();
    }
    super.dispose();
  }

  void _addIngredientInput() {
    setState(() {
      _ingredientInputs.add(IngredientInputModel(
        id: DateTime.now().millisecondsSinceEpoch,
        nameController: TextEditingController(),
        amountController: TextEditingController(),
      ));
    });
  }

  void _removeIngredientInput(int id) {
    if (_ingredientInputs.length <= 1) return;
    setState(() {
      final toRemove = _ingredientInputs.firstWhere((input) => input.id == id);
      toRemove.nameController.dispose();
      toRemove.amountController.dispose();
      _ingredientInputs.removeWhere((input) => input.id == id);
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() { _imageFile = File(pickedFile.path); });
  }

  void _saveRecipe() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('레시피 사진을 선택해주세요.'), backgroundColor: Colors.red));
        return;
      }
      final allIngredientsFilled = _ingredientInputs.every((input) => input.nameController.text.trim().isNotEmpty && input.amountController.text.trim().isNotEmpty);
      if (!allIngredientsFilled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('재료와 양을 모두 입력해주세요.'), backgroundColor: Colors.red));
        return;
      }
      setState(() { _isSaving = true; });
      final String imageUrl = _imageFile!.path; // TODO: Presigned URL 방식으로 변경 필요
      final success = await Provider.of<RecipeViewModel>(context, listen: false).addCustomRecipe(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(), // ViewModel에 전달
        ingredients: _ingredientInputs,
        instructions: _instructionsController.text.trim().split('\n').where((s) => s.trim().isNotEmpty).toList(),
        time: int.tryParse(_timeController.text) ?? 0,
        imageUrl: imageUrl,
      );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('레시피 생성에 실패했습니다.'), backgroundColor: Colors.red));
        }
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: null),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12), color: Colors.grey[200]),
                    child: _imageFile != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                        : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 50, color: Colors.grey), Text('사진을 선택하세요', style: TextStyle(color: Colors.grey))])),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildBorderBox(
                color: Colors.amber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: '레시피 제목', border: OutlineInputBorder()), validator: (value) => (value == null || value.trim().isEmpty) ? '제목을 입력하세요.' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: '레시피 간단 설명', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: '예상 소요 시간 (분 단위 숫자)', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (value) => (value == null || value.isEmpty) ? '시간을 입력하세요.' : null),
                    const SizedBox(height: 24),
                    _buildIngredientInputSection(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildBorderBox(
                color: Colors.deepOrange,
                child: _buildTextInputSection(title: '만드는 법', controller: _instructionsController, hintText: '한 줄에 한 단계씩 작성해주세요.\n예시)\n1. 돼지고기와 김치를 볶는다.\n2. 물을 붓고 끓인다.'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveRecipe,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('레시피 등록', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBorderBox({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _buildIngredientInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('재료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ingredientInputs.length,
          itemBuilder: (context, index) {
            final input = _ingredientInputs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(flex: 2, child: TextFormField(controller: input.nameController, decoration: const InputDecoration(labelText: '재료명', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: TextFormField(controller: input.amountController, decoration: const InputDecoration(labelText: '양', border: OutlineInputBorder()))),
                  IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removeIngredientInput(input.id)),
                ],
              ),
            );
          },
        ),
        TextButton.icon(icon: const Icon(Icons.add_circle, color: Colors.green), label: const Text('재료 추가', style: TextStyle(color: Colors.green)), onPressed: _addIngredientInput)
      ],
    );
  }

  Widget _buildTextInputSection({required String title, required TextEditingController controller, required String hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, maxLines: 5, decoration: InputDecoration(hintText: hintText, border: const OutlineInputBorder()), keyboardType: TextInputType.multiline, validator: (value) => (value == null || value.trim().isEmpty) ? '$title을(를) 입력하세요.' : null),
      ],
    );
  }
}
