// lib/screens/create_recipe_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../viewmodels/recipe_viewmodel.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({Key? key}) : super(key: key);

  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _cookingTimeController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _cookingTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveRecipe() {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('레시피 사진을 선택해주세요.'), backgroundColor: Colors.red),
        );
        return;
      }

      final List<String> ingredientsList = _ingredientsController.text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      final List<String> instructionsList = _instructionsController.text.split('\n').where((line) => line.trim().isNotEmpty).toList();

      final newRecipe = Recipe(
        id: "custom-${DateTime.now().millisecondsSinceEpoch}",
        name: _nameController.text,
        ingredients: ingredientsList,
        instructions: instructionsList,
        cookingTime: _cookingTimeController.text,
        imageAssetPath: _imageFile!.path,
        isCustom: true,
      );

      Provider.of<RecipeViewModel>(context, listen: false).addCustomRecipe(newRecipe);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 레시피 커스텀 화면')),
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
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: _imageFile != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                        : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text('사진을 선택하세요', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '< 제목 입력 >', border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                validator: (value) => (value == null || value.isEmpty) ? '제목을 입력하세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cookingTimeController,
                decoration: const InputDecoration(labelText: '예상 소요 시간 (예: 30분)', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? '시간을 입력하세요.' : null,
              ),
              const SizedBox(height: 24),
              _buildTextInputSection(
                title: '% 재료',
                controller: _ingredientsController,
                hintText: '예시)\n돼지고기 300g\n김치 1/4포기\n두부 1모',
                borderColor: Colors.orangeAccent,
              ),
              const SizedBox(height: 24),
              _buildTextInputSection(
                title: '% 만드는 법',
                controller: _instructionsController,
                hintText: '한 줄에 한 단계씩 작성해주세요.\n예시)\n1. 돼지고기와 김치를 볶는다.\n2. 물을 붓고 끓인다.',
                borderColor: Colors.deepOrangeAccent,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('레시피 등록', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputSection({
    required String title,
    required TextEditingController controller,
    required String hintText,
    required Color borderColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: borderColor, width: 2), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(hintText: hintText, border: InputBorder.none),
              keyboardType: TextInputType.multiline,
              validator: (value) => (value == null || value.isEmpty) ? '$title을(를) 입력하세요.' : null,
            ),
          ],
        ),
      ),
    );
  }
}
