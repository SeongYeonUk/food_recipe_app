import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:food_recipe_app/common/ingredient_helper.dart';
import 'package:food_recipe_app/viewmodels/refrigerator_viewmodel.dart';
import 'package:food_recipe_app/models/ingredient_model.dart';
import 'package:food_recipe_app/common/Component/custom_dialog.dart';
import 'package:food_recipe_app/screens/receipt_result_screen.dart';
import 'package:food_recipe_app/screens/barcode_scan_page.dart';

class RefrigeratorScreen extends StatefulWidget {
  const RefrigeratorScreen({Key? key}) : super(key: key);

  @override
  State<RefrigeratorScreen> createState() => _RefrigeratorScreenState();
}

class _RefrigeratorScreenState extends State<RefrigeratorScreen> {
  bool _isSelectionMode = false;
  final Set<Ingredient> _selectedIngredients = {};
  String _selectedCategoryFilter = '전체';
  final GlobalKey _addButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RefrigeratorViewModel>(context, listen: false).fetchRefrigerators();
    });
  }

  Widget _buildRecommendationCard(RefrigeratorViewModel viewModel) {
    final expiringCount = viewModel.ingredients.where((i) => i.dDay <= 3).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("오늘은 '된장찌개' 어때요?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[700]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("현재 냉장고의 유통기한 임박 식재료는 '${expiringCount}개' 입니다.", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            key: _addButtonKey,
            onTap: () => _showAddMenu(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3)],
              ),
              child: Icon(Icons.add, size: 32, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(RefrigeratorViewModel viewModel) {
    final categories = ['전체', ...viewModel.categories];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategoryFilter == category;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (mounted) setState(() => _selectedCategoryFilter = category);
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.brown[400],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
              showCheckmark: false,
              pressElevation: 0,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(width: 8),
        ),
      ),
    );
  }

  Widget _buildCategorySections(RefrigeratorViewModel viewModel) {
    final categoriesToShow = _selectedCategoryFilter == '전체'
        ? viewModel.categories
        : [_selectedCategoryFilter];
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categoriesToShow.length,
        itemBuilder: (context, index) {
          final category = categoriesToShow[index];
          final ingredients = viewModel.ingredients.where((i) => i.category == category).toList();
          return _buildSingleCategorySection(viewModel, category, ingredients);
        },
      ),
    );
  }

  Widget _buildSingleCategorySection(RefrigeratorViewModel viewModel, String category, List<Ingredient> ingredients) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 5)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Image.asset(IngredientHelper.getImagePathForCategory(category), width: 36, height: 36),
                const SizedBox(height: 4),
                Text(category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ingredients.isEmpty
                  ? const SizedBox(height: 80, child: Center(child: Text('식재료 없음', style: TextStyle(color: Colors.grey))))
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.8,
                ),
                itemCount: ingredients.length,
                itemBuilder: (context, index) => _buildIngredientItem(context, viewModel, ingredients[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(BuildContext context, RefrigeratorViewModel viewModel, Ingredient ingredient) {
    final isSelected = _selectedIngredients.contains(ingredient);
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          if (mounted) setState(() {
            if (isSelected) {
              _selectedIngredients.remove(ingredient);
              if (_selectedIngredients.isEmpty) _isSelectionMode = false;
            } else {
              _selectedIngredients.add(ingredient);
            }
          });
        } else {
          _showIngredientDetailDialog(ingredient);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode && mounted) setState(() {
          _isSelectionMode = true;
          _selectedIngredients.add(ingredient);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(IngredientHelper.getImagePathForCategory(ingredient.category), width: 40, height: 40, fit: BoxFit.contain),
                Positioned(top: -4, right: -4, child: IngredientHelper.getWarningIcon(ingredient.dDay) ?? const SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 8),
            Text(ingredient.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
              onPressed: () {},
              child: Text("레시피 검색 (${_selectedIngredients.length})", style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (mounted) setState(() {
                  _isSelectionMode = false;
                  _selectedIngredients.clear();
                });
              },
              child: const Text("선택 취소"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefrigeratorSelector(RefrigeratorViewModel viewModel) {
    if (viewModel.refrigerators.length <= 1) return const SizedBox.shrink();
    return Container(
      height: 50 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(viewModel.refrigerators.length, (index) {
          final isSelected = viewModel.selectedIndex == index;
          return GestureDetector(
            onTap: () => viewModel.selectRefrigerator(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: isSelected ? const Border(bottom: BorderSide(color: Colors.teal, width: 3)) : null,
              ),
              child: Text(
                viewModel.refrigerators[index].name,
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.teal : Colors.grey[700]),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RefrigeratorViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.refrigerators.isEmpty) {
          return Scaffold(appBar: AppBar(title: const Text("나의 냉장고")), body: const Center(child: CircularProgressIndicator()));
        }
        if (viewModel.errorMessage != null) {
          return Scaffold(appBar: AppBar(title: const Text("나의 냉장고")), body: Center(child: Text(viewModel.errorMessage!)));
        }
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text("나의 냉장고"),
            leading: const BackButton(),
            elevation: 0,
            backgroundColor: Colors.grey[100],
          ),
          body: Column(
            children: [
              _buildRecommendationCard(viewModel),
              _buildCategoryFilters(viewModel),
              _buildCategorySections(viewModel),
            ],
          ),
          bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : _buildRefrigeratorSelector(viewModel),
        );
      },
    );
  }

  void _showAddMenu(BuildContext buildContext) {
    final viewModel = Provider.of<RefrigeratorViewModel>(context, listen: false);
    final RenderBox? renderBox = _addButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    showGeneralDialog(
      context: buildContext,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(buildContext).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              top: offset.dy + size.height - 10,
              right: MediaQuery.of(context).size.width - offset.dx - size.width,
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  alignment: Alignment.topRight,
                  child: _buildMenuCard(dialogContext, viewModel),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuCard(BuildContext dialogContext, RefrigeratorViewModel viewModel) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOptionItem(
                icon: Icons.edit_note_outlined,
                text: '직접 입력',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showIngredientDialog(context, viewModel, null);
                },
              ),
              _buildOptionItem(
                icon: Icons.qr_code_scanner_outlined,
                text: '바코드 입력',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  // ▼▼▼ [핵심 수정] 이 부분을 주석 처리합니다 ▼▼▼
                  /*
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BarcodeScanPage(
                      showAddDialog: _showIngredientDialog,
                    ),
                  ));
                  */
                  // ▲▲▲ 여기까지 ▲▲▲
                  // 임시로 스낵바를 띄워 기능이 비활성화되었음을 알립니다.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('바코드 입력 기능은 임시로 비활성화되었습니다.')),
                  );
                },
              ),
              _buildOptionItem(
                icon: Icons.receipt_long_outlined,
                text: '영수증 입력',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _pickImageAndScan(context, viewModel);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
      ),
    );
  }

  void _showIngredientDetailDialog(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Image.asset(IngredientHelper.getImagePathForCategory(ingredient.category), width: 28, height: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(ingredient.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("분류: ${ingredient.category}"),
            Text("수량: ${ingredient.quantity}"),
            Text("유통기한: ${DateFormat('yyyy.MM.dd').format(ingredient.expiryDate)}"),
            Row(
              children: [
                Text("남은 d-day: ${ingredient.dDayText}", style: TextStyle(color: ingredient.dDayColor, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                IngredientHelper.getWarningIcon(ingredient.dDay) ?? const SizedBox.shrink(),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("닫기")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showIngredientDialog(context, context.read<RefrigeratorViewModel>(), ingredient);
            },
            child: const Text("변경"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageAndScan(BuildContext context, RefrigeratorViewModel viewModel) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final NavigatorState? nav = Navigator.maybeOf(context, rootNavigator: true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (!mounted || image == null) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final success = await viewModel.startOcrScan(File(image.path));
      if (!mounted) return;
      await nav?.maybePop();
      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: viewModel, child: const ReceiptResultScreen())),
        );
      } else {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(viewModel.ocrErrorMessage ?? '알 수 없는 오류가 발생했습니다.'), backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      await nav?.maybePop();
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('이미지를 처리하는 중 오류 발생: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showIngredientDialog(
      BuildContext context, RefrigeratorViewModel viewModel, Ingredient? ingredient, {String? initialName}) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (viewModel.refrigerators.isEmpty) return;
    final currentRefrigeratorId = viewModel.refrigerators[viewModel.selectedIndex].id;
    final result = await showDialog<Ingredient>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: viewModel,
        child: IngredientFormDialog(
          ingredient: ingredient,
          initialRefrigeratorId: currentRefrigeratorId,
          initialName: initialName,
        ),
      ),
    );
    if (result != null) {
      bool success;
      if (ingredient == null) {
        success = await viewModel.addIngredient(result);
      } else {
        success = await viewModel.updateIngredient(result);
      }
      if (!mounted) return;
      if (!success) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('작업에 실패했습니다. 다시 시도해주세요.'), backgroundColor: Colors.red));
      }
    }
  }
}
