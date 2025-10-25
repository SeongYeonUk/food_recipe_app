import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:food_recipe_app/services/calendar_client.dart'; // [추가] 캘린더 서비스 import
import '../viewmodels/refrigerator_viewmodel.dart';
import '../models/ingredient_model.dart';
import '../common/Component/custom_dialog.dart';
import 'receipt_result_screen.dart';
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
      Provider.of<RefrigeratorViewModel>(context, listen: false).fetchRefrigerators();
    });
  }

  // ▼▼▼ 유통기한 임박 상품을 캘린더에 등록
  Future<void> _syncExpiringItemsToCalendar() async {
    if (!mounted) return;

    final calendarClient = context.read<CalendarClient>();
    final refrigeratorViewModel = context.read<RefrigeratorViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!calendarClient.isLoggedIn) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('구글 캘린더 연동이 필요합니다. 설정 화면에서 연동해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final expiringIngredients = refrigeratorViewModel.filteredIngredients.where((item) {
      final difference = item.expiryDate.difference(DateTime.now()).inDays;
      return difference >= 0 && difference <= 3;
    }).toList();

    if (expiringIngredients.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('유통기한이 임박한(3일 이내) 식재료가 없습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int successCount = 0;
    for (final ingredient in expiringIngredients) {
      final success = await calendarClient.addExpiryDateEvent(
        ingredientName: ingredient.name,
        expiryDate: ingredient.expiryDate,
      );
      if (success) successCount++;
    }

    if (!mounted) return;
    navigator.pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('$successCount개의 유통기한 임박 알림을 구글 캘린더에 추가했습니다!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  // ▲▲▲

  @override
  Widget build(BuildContext context) {
    return Consumer<RefrigeratorViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("우리집 냉장고"),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: _syncExpiringItemsToCalendar,
                tooltip: '유통기한 임박 상품 캘린더에 등록',
              ),
            ],
          ),
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

  Widget _buildIngredientListContainer(
      BuildContext context,
      RefrigeratorViewModel viewModel,
      ) {
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
              Text(viewModel.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: () => viewModel.fetchRefrigerators(), child: const Text('다시 시도')),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        final formattedDate = DateFormat('yyyy.MM.dd');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _showIngredientDialog(context, viewModel, ingredient),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: AutoSizeText(
                        ingredient.dDayText,
                        style: TextStyle(color: ingredient.dDayColor, fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        minFontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          ingredient.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          maxLines: 2,
                          minFontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '카테고리: ${ingredient.category} / 수량: ${ingredient.quantity}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '유통기한: ${formattedDate.format(ingredient.expiryDate)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.8)),
                    onPressed: () => _confirmAndDelete(context, viewModel, ingredient),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ▼▼▼ 오버레이 버튼 선택시 올바른 컨텍스트(rootContext)로 전달
  void _showFloatingAddOptions(
      BuildContext context,
      RefrigeratorViewModel viewModel,
      ) {
    final rootContext = context; // ✅ Scaffold/Navigator 포함 컨텍스트 보관

    final overlay = Overlay.of(context);
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FloatingAddOptionsMenu(
        offset: offset,
        size: size,
        onClose: () => overlayEntry.remove(),
        onSelectOption: (String optionText) {
          overlayEntry.remove();
          if (optionText == '직접 입력') {
            _showIngredientDialog(rootContext, viewModel, null); // ✅ rootContext 사용
          } else if (optionText == '바코드 입력') {
            Navigator.of(rootContext).push( // ✅ rootContext 사용
              MaterialPageRoute(
                builder: (_) => BarcodeScanPage(
                  showAddDialog: ({required BuildContext context, String? initialName}) {
                    return _showIngredientDialog(
                      rootContext,
                      viewModel,
                      null,
                      initialName: initialName,
                    );
                  },
                ),
              ),
            );
          } else if (optionText == '영수증 입력') {
            _pickImageAndScan(rootContext, viewModel); // ✅ rootContext 사용
          } else {
            _showComingSoonSnackBar(rootContext, optionText); // ✅ rootContext 사용
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
  // ▲▲▲

  // ▼▼▼ 카메라 촬영 → OCR → 결과 화면 이동 (안전 버전)
  Future<void> _pickImageAndScan(
      BuildContext context,
      RefrigeratorViewModel viewModel,
      ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // ✅ NavigatorState를 사전 확보(없으면 null)
    final NavigatorState? nav =
        Navigator.maybeOf(context) ?? (mounted ? Navigator.of(context, rootNavigator: true) : null);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (!mounted) return;
      if (image == null) return;

      // 로딩 다이얼로그 (await 안 걸고 나중에 maybePop으로 닫음)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final success = await viewModel.startOcrScan(File(image.path));

      if (!mounted) return;
      await nav?.maybePop(); // ✅ 안전하게 닫기

      if (success) {
        Navigator.of(context).push(
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
      // 실패 시에도 안전하게 닫기 시도
      await nav?.maybePop();
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
  // ▲▲▲

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName 기능은 현재 준비 중입니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
              left: MediaQuery.of(context).size.width / 2 -
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
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
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

  Future<void> _showIngredientDialog(
      BuildContext context,
      RefrigeratorViewModel viewModel,
      Ingredient? ingredient, {
        String? initialName,
      }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (viewModel.refrigerators.isEmpty) return;
    final currentRefrigeratorId =
        viewModel.refrigerators[viewModel.selectedIndex].id;

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
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('작업에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

// + 버튼을 눌렀을 때 나타나는 오버레이 메뉴 위젯
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
          right:
          MediaQuery.of(context).size.width - widget.offset.dx - widget.size.width,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
