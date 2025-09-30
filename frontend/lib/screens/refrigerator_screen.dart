import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../viewmodels/refrigerator_viewmodel.dart';
import '../models/ingredient_model.dart';
import 'package:food_recipe_app/common/Component/custom_dialog.dart';

// 새로 만든 OCR 결과 화면 import
import 'receipt_result_screen.dart';

// [가정] 바코드 스캔 페이지 경로
import 'barcode_scan_page.dart';

class RefrigeratorScreen extends StatefulWidget {
  const RefrigeratorScreen({Key? key}) : super(key: key);

  @override
  State<RefrigeratorScreen> createState() => _RefrigeratorScreenState();
}

class _RefrigeratorScreenState extends State<RefrigeratorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // [수정] 중복 호출 제거
      Provider.of<RefrigeratorViewModel>(
        context,
        listen: false,
      ).fetchRefrigerators();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RefrigeratorViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(title: const Text("우리집 냉장고")),
          body: Column(
            children: [
              const SizedBox(height: 20),
              _buildRefrigeratorAnimator(context, viewModel),
              const SizedBox(height: 10),
              const Divider(),
              Expanded(
                child: _buildIngredientListContainer(context, viewModel),
              ),
            ],
          ),
          floatingActionButton: Builder(
            builder: (fabContext) {
              return FloatingActionButton(
                onPressed: () => _showFloatingAddOptions(fabContext, viewModel),
                child: const Icon(Icons.add),
              );
            },
          ),
        );
      },
    );
  }

  // ===== 목록 컨테이너 (로딩/에러/정상) =====
  Widget _buildIngredientListContainer(
    BuildContext context,
    RefrigeratorViewModel viewModel,
  ) {
    // [수정] 잘못된 함수 시그니처 및 조건문 결합
    if (viewModel.isLoading && viewModel.refrigerators.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => viewModel.fetchRefrigerators(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (viewModel.refrigerators.isEmpty) {
      return const Center(child: Text("냉장고 정보가 없습니다."));
    }
    return _buildIngredientList(context, viewModel);
  }

  void _showFloatingAddOptions(
    BuildContext context,
    RefrigeratorViewModel viewModel,
  ) {
    final overlay = Overlay.of(context);
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FloatingAddOptionsMenu(
        offset: offset,
        size: size,
        onClose: () => overlayEntry.remove(),
        onSelectOption: (String optionText) {
          // [수정] 중복 호출 제거
          overlayEntry.remove();
          if (optionText == '직접 입력') {
            _showIngredientDialog(context, viewModel, null);
          } else if (optionText == '바코드 입력') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BarcodeScanPage(
                  showAddDialog:
                      ({required BuildContext context, String? initialName}) {
                        return _showAddIngredientPrefilled(
                          context,
                          viewModel,
                          initialName: initialName,
                        );
                      },
                ),
              ),
            );
          } else if (optionText == '영수증 입력') {
            _pickImageAndScan(context, viewModel);
          } else {
            _showComingSoonSnackBar(context, optionText);
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  Future<void> _pickImageAndScan(
    BuildContext context,
    RefrigeratorViewModel viewModel,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) return;
      if (!mounted) return;

      final success = await viewModel.startOcrScan(File(image.path));

      if (!mounted) return;

      if (success) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: viewModel,
              child: const ReceiptResultScreen(),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(viewModel.ocrErrorMessage ?? '알 수 없는 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('이미지를 처리하는 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName 기능은 현재 준비 중입니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ===== 상단 냉장고 선택 애니메이션 =====
  Widget _buildRefrigeratorAnimator(
    BuildContext context,
    RefrigeratorViewModel viewModel,
  ) {
    if (viewModel.refrigerators.isEmpty) {
      return const SizedBox(height: 180);
    }
    final double centerSize = 140;
    final double sideSize = 110;

    return SizedBox(
      height: 180,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            if (viewModel.selectedIndex < viewModel.refrigerators.length - 1) {
              viewModel.selectRefrigerator(viewModel.selectedIndex + 1);
            }
          } else if (details.primaryVelocity! > 0) {
            if (viewModel.selectedIndex > 0) {
              viewModel.selectRefrigerator(viewModel.selectedIndex - 1);
            }
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(viewModel.refrigerators.length, (index) {
            bool isSelected = index == viewModel.selectedIndex;
            final double targetPosition =
                (index - viewModel.selectedIndex) * (sideSize + 40.0);
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left:
                  MediaQuery.of(context).size.width / 2 -
                  (isSelected ? centerSize : sideSize) / 2 +
                  targetPosition,
              child: GestureDetector(
                onTap: () => viewModel.selectRefrigerator(index),
                onLongPress: () =>
                    _showImagePickerDialog(context, viewModel, index),
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? centerSize : sideSize,
                    height: isSelected ? centerSize : sideSize,
                    decoration: BoxDecoration(
                      // [수정] 잘못된 삼항 연산자 수정
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          viewModel.refrigerators[index].currentImage,
                          height: 64,
                          width: 64,
                          color: isSelected
                              ? null
                              : Colors.grey.withOpacity(0.7),
                          colorBlendMode: BlendMode.modulate,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.refrigerators[index].name,
                          style: TextStyle(
                            // [수정] 중복 속성 제거
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ===== 식재료 리스트 =====
  Widget _buildIngredientList(
    BuildContext context,
    RefrigeratorViewModel viewModel,
  ) {
    final ingredients = viewModel.filteredIngredients;
    if (ingredients.isEmpty) {
      return const Center(
        child: Text(
          "저장된 식재료가 없어요!\n아래의 '+' 버튼으로 식재료를 추가해보세요.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
        ),
      );
    }
    return ListView.builder(
      key: ValueKey(viewModel.selectedIndex),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        final formattedDate = DateFormat('yyyy.MM.dd');
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: SizedBox(
              width: 60,
              child: Center(
                child: Text(
                  ingredient.dDayText,
                  style: TextStyle(
                    color: ingredient.dDayColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // [수정] 중복된 title, subtitle 제거
            title: Text(
              ingredient.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              '카테고리: ${ingredient.category} / 수량: ${ingredient.quantity}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedDate.format(ingredient.expiryDate),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '등록일: ${formattedDate.format(ingredient.registrationDate)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent.withOpacity(0.8),
                  ),
                  onPressed: () =>
                      _confirmAndDelete(context, viewModel, ingredient),
                ),
              ],
            ),
            onTap: () => _showIngredientDialog(context, viewModel, ingredient),
          ),
        );
      },
    );
  }

  // ===== '식재료 추가/수정' 다이얼 =====
  Future<void> _showIngredientDialog(
    BuildContext context,
    RefrigeratorViewModel viewModel,
    Ingredient? ingredient,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (viewModel.refrigerators.isEmpty) return;
    final currentRefrigeratorId =
        viewModel.refrigerators[viewModel.selectedIndex].id;

    final result = await showDialog<Ingredient>(
      context: context,
      barrierDismissible: false,
      // [수정] 충돌된 builder 로직을 Provider.value를 사용하는 방식으로 통일
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: viewModel,
        child: IngredientFormDialog(
          ingredient: ingredient,
          initialRefrigeratorId: currentRefrigeratorId,
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

      // [수정] 비동기 작업 후 안전하게 UI 처리
      if (!mounted) return;

      if (!success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('작업에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 바코드 경로: '상품명 프리필'로 다이얼 열기
  Future<void> _showAddIngredientPrefilled(
    BuildContext context,
    RefrigeratorViewModel viewModel, {
    String? initialName,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final currentRefrigeratorId =
        viewModel.refrigerators[viewModel.selectedIndex].id;

    final result = await showDialog<Ingredient>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangeNotifierProvider.value(
        value: viewModel,
        child: IngredientFormDialog(
          ingredient: null,
          initialRefrigeratorId: currentRefrigeratorId,
          initialName: initialName,
        ),
      ),
    );

    if (result != null) {
      final success = await viewModel.addIngredient(result);
      if (!mounted) return;
      if (!success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('작업에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== 삭제 확인 =====
  Future<void> _confirmAndDelete(
    BuildContext context,
    RefrigeratorViewModel viewModel,
    Ingredient ingredient,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('\'${ingredient.name}\'을(를) 정말 삭제하시겠습니까?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await viewModel.deleteIngredient(ingredient.id);

      if (!mounted) return;

      if (!success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('삭제에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== 냉장고 이미지 변경 =====
  Future<void> _showImagePickerDialog(
    BuildContext context,
    RefrigeratorViewModel viewModel,
    int index,
  ) async {
    final availableImages = viewModel.refrigerators[index].availableImages;
    final selectedImage = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${viewModel.refrigerators[index].name} 이미지 변경'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableImages.length,
            itemBuilder: (context, imageIndex) {
              final imagePath = availableImages[imageIndex];
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(imagePath),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (selectedImage != null) {
      viewModel.changeRefrigeratorImage(index, selectedImage);
    }
  }
}

class _FloatingAddOptionsMenu extends StatefulWidget {
  final Offset offset;
  final Size size;
  final VoidCallback onClose;
  final Function(String) onSelectOption;

  const _FloatingAddOptionsMenu({
    required this.offset,
    required this.size,
    required this.onClose,
    required this.onSelectOption,
  });

  @override
  _FloatingAddOptionsMenuState createState() => _FloatingAddOptionsMenuState();
}

class _FloatingAddOptionsMenuState extends State<_FloatingAddOptionsMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // [수정] 중복 초기화 코드 제거
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _close() {
    _animationController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
        ),
        Positioned(
          // [수정] 중복 속성 제거
          right:
              MediaQuery.of(context).size.width -
              widget.offset.dx -
              widget.size.width,
          bottom: MediaQuery.of(context).size.height - widget.offset.dy,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.bottomRight,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Card(
                  elevation: 8.0,
                  // [수정] 중복 속성 제거
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // [수정] 중복된 메뉴 아이템 제거
                      children: [
                        _buildOptionItem(
                          icon: Icons.edit_note_outlined,
                          text: '직접 입력',
                        ),
                        _buildOptionItem(
                          icon: Icons.qr_code_scanner_outlined,
                          text: '바코드 입력',
                        ),
                        _buildOptionItem(
                          icon: Icons.receipt_long_outlined,
                          text: '영수증 입력',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem({required IconData icon, required String text}) {
    return InkWell(
      onTap: () {
        widget.onSelectOption(text);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
      ),
    );
  }
}
