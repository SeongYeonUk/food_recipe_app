// lib/screens/community/review_creation_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/recipe_model.dart';
import '../../viewmodels/review_viewmodel.dart';

class ReviewCreationScreen extends StatefulWidget {
  final Recipe recipe;
  const ReviewCreationScreen({super.key, required this.recipe});

  @override
  State<ReviewCreationScreen> createState() => _ReviewCreationScreenState();
}

class _ReviewCreationScreenState extends State<ReviewCreationScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() { _imageFile = File(pickedFile.path); });
  }

  void _saveReview() {
    if (_isSaving) return;
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isSaving = true; });

    // ViewModel을 통해 프론트엔드에 임시 후기 저장
    Provider.of<ReviewViewModel>(context, listen: false).addReview(
      recipeName: widget.recipe.name,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      imageUrl: _imageFile?.path,
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('후기가 등록되었습니다!'), backgroundColor: Colors.green));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.recipe.name} 후기 작성')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12), color: Colors.grey[200]),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 50, color: Colors.grey), Text('사진 첨부 (선택)', style: TextStyle(color: Colors.grey))])),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: '후기 제목', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _contentController, maxLines: 5, decoration: const InputDecoration(labelText: '후기 내용', border: OutlineInputBorder(), alignLabelWithHint: true)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveReview,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSaving
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('후기 등록하기', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
