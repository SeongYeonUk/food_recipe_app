// lib/screens/create_recipe_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/recipe_viewmodel.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({Key? key}) : super(key: key);

  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _timeController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _timeController.dispose();
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

  void _saveRecipe() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('레시피 사진을 선택해주세요.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() { _isSaving = true; });

      // TODO: 1. 이미지 업로드 API를 호출하고 실제 imageUrl을 받아와야 함
      // final imageUrl = await _apiClient.uploadImage(_imageFile!);
      final tempImageUrl = "https://img.freepik.com/free-photo/kimchi-ready-to-eat_1339-2041.jpg";

      final recipeData = {
        'title': _titleController.text,
        'ingredients': _ingredientsController.text,
        'instructions': _instructionsController.text,
        'time': int.tryParse(_timeController.text) ?? 0,
        'imageUrl': tempImageUrl,
      };

      final success = await Provider.of<RecipeViewModel>(context, listen: false).addCustomRecipe(recipeData);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('레시피 생성에 실패했습니다.'), backgroundColor: Colors.red),
          );
        }
      }
      setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나만의 레시피 만들기')),
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
                      color: Colors.grey[200],
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
                controller: _titleController,
                decoration: const InputDecoration(labelText: '레시피 제목', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? '제목을 입력하세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: '예상 소요 시간 (분 단위 숫자)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => (value == null || value.isEmpty) ? '시간을 입력하세요.' : null,
              ),
              const SizedBox(height: 24),
              _buildTextInputSection(
                title: '재료',
                controller: _ingredientsController,
                hintText: '한 줄에 재료 하나씩 작성해주세요.\n예시)\n돼지고기 300g\n김치 1/4포기',
              ),
              const SizedBox(height: 24),
              _buildTextInputSection(
                title: '만드는 법',
                controller: _instructionsController,
                hintText: '한 줄에 한 단계씩 작성해주세요.\n예시)\n1. 돼지고기와 김치를 볶는다.\n2. 물을 붓고 끓인다.',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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

  Widget _buildTextInputSection({
    required String title,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.multiline,
          validator: (value) => (value == null || value.isEmpty) ? '$title을(를) 입력하세요.' : null,
        ),
      ],
    );
  }
}
