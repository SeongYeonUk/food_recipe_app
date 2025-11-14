// 📁 lib/screens/refrigerator_screen.dart (최적화 완료)

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:food_recipe_app/common/Component/custom_dialog.dart';
import 'package:food_recipe_app/common/api_client.dart';
import 'package:food_recipe_app/common/ingredient_helper.dart';
import 'package:food_recipe_app/models/ingredient_model.dart';
import 'package:food_recipe_app/screens/barcode_scan_page.dart';
import 'package:food_recipe_app/screens/receipt_result_screen.dart';
import 'package:food_recipe_app/screens/recipe_recommendation_screen.dart';
import 'package:food_recipe_app/viewmodels/recipe_viewmodel.dart';
import 'package:food_recipe_app/models/recipe_model.dart';
import 'package:food_recipe_app/screens/recipe_detail_screen.dart';
import 'package:food_recipe_app/viewmodels/refrigerator_viewmodel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'community_screen.dart';

class RefrigeratorScreen extends StatefulWidget {
  const RefrigeratorScreen({Key? key}) : super(key: key);

  @override
  State<RefrigeratorScreen> createState() => _RefrigeratorScreenState();
}

class _RefrigeratorScreenState extends State<RefrigeratorScreen> {
  static const String _kAll = '\uC804\uCCB4';
  bool _recommendCollapsed = false;
  bool _useFallbackImage = false; // legacy flag, kept for safety
  int _recImageIndex = 0;
  List<String> get _recImageCandidates {
    final base = ApiClient.baseUrl;
    return [
      '$base/images/galbijjim.png',                    // ASCII filename (preferred)
      '$base/static/images/galbijjim.png',             // if server maps under /static
      '$base/static.images/galbijjim.png',             // if folder name is literally 'static.images'
      '$base/galbijjim.png',                           // if served from root
      '$base/images/%EA%B0%88%EB%B9%84%EC%B0%9F.png',   // URL-encoded Korean fallback
      '$base/images/eggrice.jpeg',                     // final safe fallback
    ];
  }
  bool _isSelectionMode = false;
  final Set<Ingredient> _selectedIngredients = {};
  String _selectedCategoryFilter = _kAll;
  final GlobalKey _addButtonKey = GlobalKey();
  bool _alertsExpanded = false;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _tempFilePath;
  final String _backendUrl = "http://10.0.2.2:8080/api/items/voice";

  void _cancelSelection() {
    if (mounted && (_isSelectionMode || _selectedIngredients.isNotEmpty)) {
      setState(() {
        _isSelectionMode = false;
        _selectedIngredients.clear();
      });
    }
  }

  List<String> _buildSelectedIngredientNames() {
    final seen = <String>{};
    final result = <String>[];
    for (final ingredient in _selectedIngredients) {
      final normalized = ingredient.name.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) {
        result.add(normalized);
      }
    }
    return result;
  }

  Widget _buildRecommendationCardNew(RefrigeratorViewModel viewModel) {
  final recipe = Recipe(
    id: -9999,
    name: '갈비찜',
    description: '\uB2EC\uD070\uD55C \uC591\uB150\uC758 \uBD80\uB4DC\uB7FD\uAC8C \uAC08\uBE44\uCC1F',
    ingredients: ['\uC18C\uAC08\uBE44','\uBB34','\uB2F9\uADF8\uB7FC','\uAC10\uC790','\uB300\uD30C','\uAC04\uC7A5','\uC124\uD0D5','\uB9C8\uB451'],
    instructions: [
      '\uC18C\uAC08\uBE44\uB294 \uCC2C\uBB3C\uC5D0 \uB2F4\uAC70 \uD54F\uBB3C\uC744 \uBE7C\uC5B4\uC694.',
      '\uBB34, \uB2F9\uADF8\uB7FC, \uAC10\uC790\uB97C \uD070\uC7A5\uD558\uAC8C \uC798\uC5B4\uC694.',
      '\uAC04\uC7A5, \uC124\uD0D5, \uB2E4\uC9D1 \uB9C8\uB451 \uB4F1\uC73C\uB85C \uC591\uB150\uC7A5\uC744 \uB9CC\uB4DC\uC138\uC694.',
      '\uAC08\uBE44\uB97C \uD55C \uBC88 \uC0C1\uB9C8\uD558\uC5EC \uBD88\uC21C\uBB3C\uC744 \uC81C\uAC70\uD574\uC694.',
      '\uB0B4\uBE44\uC5D0 \uAC08\uBE44, \uC57C\uCC44, \uC591\uB150\uC7A5\uC744 \uB123\uACE0 \uBD80\uB4DC\uB7FD\uAC8C \uC878\uC5EC\uC694.',
    ],
    cookingTime: '60분',
    imageUrl: '${ApiClient.baseUrl}/images/galbijjim.png',
    isCustom: false,
    authorNickname: 'AI',
    isFavorite: false,
  );

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("오늘은 '갈비찜' 어때요?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              AnimatedRotation(
                turns: _recommendCollapsed ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => setState(() => _recommendCollapsed = !_recommendCollapsed),
                ),
              ),
            ],
          ),
          if (!_recommendCollapsed) ...[
            const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 3 / 2, // close to galbijjim image ratio, minimizes crop
                  child: Image.network(
                    _recImageCandidates[_recImageIndex.clamp(0, _recImageCandidates.length - 1)],
                    fit: BoxFit.cover,
                    key: ValueKey(_recImageIndex),
                    errorBuilder: (context, error, stack) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _recImageIndex < _recImageCandidates.length - 1) {
                          setState(() => _recImageIndex += 1);
                        }
                      });
                      return Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('레시피 이동'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        recipe: recipe,
                        userIngredients: viewModel.ingredients.map((e) => e.name).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initRecorder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ ViewModel이 냉장고 목록 로드 및 첫 번째 냉장고 재료 로드를 모두 처리
      Provider.of<RefrigeratorViewModel>(
        context,
        listen: false,
      ).loadInitialData(); // 👈 ViewModel의 이 함수를 호출
    });
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }

  // --- 🎙️ 음성 녹음 로직 (인증 헤더 제거됨) ---
  Future<void> _initRecorder() async {
    try {
      await _recorder!.openRecorder();
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('마이크 권한이 거부되었습니다.');
      }
    } catch (e) {
      print('녹음기 초기화 실패: $e');
    }
  }

  void _handleVoiceInput() async {
    if (_recorder == null) {
      print("녹음기가 초기화되지 않았습니다.");
      return;
    }
    if (_isRecording) {
      await _stopRecordingAndSend();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _tempFilePath = '${tempDir.path}/temp_audio.wav';
      await _recorder!.startRecorder(
        toFile: _tempFilePath,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
      );
      setState(() => _isRecording = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('녹음 중... 다시 버튼을 눌러 중지하세요.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      print('녹음 시작 실패: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecordingAndSend() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final viewModel = Provider.of<RefrigeratorViewModel>(
      context,
      listen: false,
    );

    // --- ⬇️ ⬇️ ⬇️ [핵심 수정] ⬇️ ⬇️ ⬇️ ---
    // 1. 스토리지에서 "현재 유효한" 토큰을 직접 읽어옵니다.
    const storage = FlutterSecureStorage();
    final String? accessToken = await storage.read(key: 'ACCESS_TOKEN');

    // 2. 토큰이 없는지 확인합니다. (로그인이 안 된 상태)
    if (accessToken == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('오류: 로그인이 필요합니다. 앱을 재시작해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _recorder!.stopRecorder();
      setState(() => _isRecording = false);
      print("녹음 중지. 파일 경로: $_tempFilePath");

      if (_tempFilePath == null) return;

      File audioFile = File(_tempFilePath!);
      if (!await audioFile.exists()) {
        print('녹음된 파일이 없습니다.');
        return;
      }
      Uint8List audioBytes = await audioFile.readAsBytes();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('음성 분석 중...'),
          backgroundColor: Colors.grey[700],
        ),
      );
      print("백엔드로 음성 데이터 전송 중...");

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Authorization': 'Bearer $accessToken',
        },
        body: audioBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("음성 인식 및 재료 추가 성공!");
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('재료가 추가되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        // ✅ ViewModel이 재료를 다시 로드하도록 함
        await viewModel.fetchAllIngredients();
      } else {
        print("백엔드 오류: ${response.statusCode} / ${response.body}");
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('음성 분석 실패 (서버 오류)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("API 전송 오류: $e");
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('음성 전송 실패 (네트워크 오류: $e)'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (_tempFilePath != null) {
        File(_tempFilePath!).delete();
        _tempFilePath = null;
      }
    }
  }
  // --- 🎙️ 음성 로직 끝 ---

  // ✅ 최적화: ViewModel의 `urgentIngredients` 변수 직접 사용
  Widget _buildRecommendationCard(RefrigeratorViewModel viewModel) {
    // ⚠️ final expiringCount = viewModel.ingredients.where((i) => i.dDay <= 3).length; (X)
    final expiringCount = viewModel.urgentIngredients.length; // 👈 (O)

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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("오늘은 '된장찌개' 어때요?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3),
                ],
              ),
              child: Icon(Icons.add, size: 32, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 최적화: ViewModel의 `urgentIngredients`, `soonIngredients` 변수 직접 사용
  Widget _buildExpiryAlerts(RefrigeratorViewModel viewModel) {
    final urgent = viewModel.ingredients.where((i) => i.dDay <= 3).toList();
    final soon = viewModel.ingredients.where((i) => i.dDay > 3 && i.dDay <= 7).toList();

    if (urgent.isEmpty && soon.isEmpty) return const SizedBox.shrink();

    // Collapsed: compact chips with counts
    if (!_alertsExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            _buildAlertChip('위험 ', Colors.red, onTap: () => _showAlertsBottomSheet(urgent, soon)),
            const SizedBox(width: 8),
            _buildAlertChip('주의 ', Colors.orange, onTap: () => _showAlertsBottomSheet(urgent, soon)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.expand_more),
              onPressed: () => setState(() => _alertsExpanded = true),
              tooltip: '펼치기',
            ),
          ],
        ),
      );
    }

    Widget buildRow(String title, Color color, List<Ingredient> list) {
      if (list.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 6, spreadRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final ing = list[index];
                  return GestureDetector(
                    onTap: () => _showIngredientDetailDialog(ing),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Image.asset(IngredientHelper.getImagePath(ing.category, ing.iconIndex), width: 32, height: 32),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(ing.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.2)),
                                Text(
                                  ing.dDayText,
                                  style: TextStyle(fontSize: 12, height: 1.1, color: ing.dDayColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.expand_less),
                onPressed: () => setState(() => _alertsExpanded = false),
                tooltip: '펼치기',
              ),
            ],
          ),
        ),
        buildRow('위험 (3일 이하)', Colors.red, urgent),
        buildRow('주의 (4~7일)', Colors.orange, soon),
      ],
    );
  }

  Widget _buildCategoryFiltersWithButton(RefrigeratorViewModel viewModel) {
    final categories = [_kAll, ...viewModel.categories];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
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
                      if (mounted) {
                        setState(() => _selectedCategoryFilter = category);
                        _cancelSelection();
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.brown[400],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                    ),
                    showCheckmark: false,
                    pressElevation: 0,
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              key: _addButtonKey,
              onTap: () => _showAddMenu(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3),
            ],
                ),
                child: Icon(Icons.add, size: 22, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertChip(String text, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3)],
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 16),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // ✅ 최적화: ViewModel의 `categories` 변수 직접 사용
  Widget _buildCategoryFilters(RefrigeratorViewModel viewModel) {
    final categories = [_kAll, ...viewModel.categories];
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
                if (mounted) {
                  setState(() => _selectedCategoryFilter = category);
                  _cancelSelection();
                }
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

  // ✅ 최적화: ViewModel의 `categories` 변수 직접 사용
  Widget _buildCategorySections(RefrigeratorViewModel viewModel) {
    final categoriesToShow = _selectedCategoryFilter == _kAll ? viewModel.categories : [_selectedCategoryFilter];
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
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
      padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), spreadRadius: 2, blurRadius: 5)],
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
                  ? const SizedBox(height: 80, child: Center(child: Text('재료 없음', style: TextStyle(color: Colors.grey))))
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
          color: isSelected ? Colors.red.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.red : Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(IngredientHelper.getImagePath(ingredient.category, ingredient.iconIndex), width: 40, height: 40, fit: BoxFit.contain),
                Positioned(top: -4, right: -4, child: IngredientHelper.getWarningIcon(ingredient.dDay) ?? const SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (_) {
                final int d = ingredient.dDay;
                Color? bg;
                Color fg = Colors.black87;
                if (d <= 3) {
                  bg = const Color(0xFFFFE5E0); // soft red background
                } else if (d <= 7) {
                  bg = const Color(0xFFFFF0E0); // soft orange background
                }
                final Widget label = Text(
                  ingredient.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                );
                return bg == null
                    ? label
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DefaultTextStyle.merge(style: TextStyle(color: fg), child: label),
                      );
              },
            ),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
              onPressed: () {
                final ingredientNames = _buildSelectedIngredientNames();
                if (ingredientNames.isEmpty) return;
                final displayQuery = ingredientNames.join(' + ');
                _cancelSelection();
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CommunityScreen(
                      initialSearchQuery: displayQuery,
                      initialIngredientNames: ingredientNames,
                    ),
                  ),
                );
              },
              child: Text("레시피 검색(${_selectedIngredients.length})", style: const TextStyle(color: Colors.white)),
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
              child: const Text("선택취소"),
            ),
          ),
        ],
      ),
    );
  }

  // --- ✅ (최적화) build 메소드 ---
  @override
  Widget build(BuildContext context) {
    return Consumer<RefrigeratorViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.refrigerators.isEmpty) {
          return Scaffold(appBar: null, body: const Center(child: CircularProgressIndicator()));
        }
        if (viewModel.errorMessage != null) {
          return Scaffold(appBar: null, body: Center(child: Text(viewModel.errorMessage!)));
        }
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: null,
          body: SafeArea(
            top: true,
            child: Column(
              children: [
                _buildRecommendationCardNew(viewModel),
                _buildCategoryFiltersWithButton(viewModel),
                _buildExpiryAlertsCompact(viewModel),
                _buildCategorySections(viewModel),
              ],
            ),
          ),
          bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : _buildRefrigeratorSelector(viewModel),
        );
      },
    );
  }

  Widget _buildRefrigeratorSelector(RefrigeratorViewModel viewModel) {
    if (viewModel.refrigerators.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(viewModel.refrigerators.length, (index) {
          final isSelected = index == viewModel.selectedIndex;
          return TextButton(
            onPressed: () {
              _cancelSelection();
              viewModel.selectRefrigerator(index);
            },
            child: Text(
              viewModel.refrigerators[index].name,
              style: TextStyle(color: isSelected ? Colors.teal : Colors.grey[700]),
            ),
          );
        }),
      ),
    );
  }

  // Compact alerts: show chips with counts; tap opens a bottom sheet for details
  Widget _buildExpiryAlertsCompact(RefrigeratorViewModel viewModel) {
    final urgent = viewModel.ingredients.where((i) => i.dDay <= 3).toList();
    final soon = viewModel.ingredients.where((i) => i.dDay > 3 && i.dDay <= 7).toList();
    if (urgent.isEmpty && soon.isEmpty) return const SizedBox.shrink();

    void openSheet() => _showAlertsBottomSheet(urgent, soon);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _buildAlertChip('위험 ${urgent.length}', Colors.red, onTap: openSheet),
          const SizedBox(width: 8),
          _buildAlertChip('주의 ${soon.length}', Colors.orange, onTap: openSheet),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.expand_more),
            onPressed: openSheet,
            tooltip: '펼치기',
          ),
        ],
      ),
    );
  }

  void _showAlertsBottomSheet(List<Ingredient> urgent, List<Ingredient> soon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('유통기한 임박 식재료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAlertListSection('위험 (3일 이하)', Colors.red, urgent),
                    _buildAlertListSection('주의 (4~7일)', Colors.orange, soon),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlertListSection(String title, Color color, List<Ingredient> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final ing = list[index];
                return GestureDetector(
                  onTap: () => _showIngredientDetailDialog(ing),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Image.asset(IngredientHelper.getImagePath(ing.category, ing.iconIndex), width: 32, height: 32),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(ing.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.2)),
                              Text(ing.dDayText, style: TextStyle(fontSize: 12, height: 1.1, color: ing.dDayColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext buildContext) {
    final viewModel = Provider.of<RefrigeratorViewModel>(context, listen: false);
    _cancelSelection();
    final RenderBox? renderBox = _addButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    showGeneralDialog(
      context: buildContext,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(buildContext).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
                icon: Icons.mic_outlined,
                text: '음성 입력',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _handleVoiceInput();
                },
              ),
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BarcodeScanPage(
                        showAddDialog: ({required BuildContext context, String? initialName}) async {
                          await _showIngredientDialog(context, viewModel, null, initialName: initialName);
                        },
                      ),
                    ),
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
            Image.asset(IngredientHelper.getImagePath(ingredient.category, ingredient.iconIndex), width: 28, height: 28),
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
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: Text("'${ingredient.name}'를 삭제할까요?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
                    ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('삭제')),
                  ],
                ),
              );
              if (confirm == true) {
                await context.read<RefrigeratorViewModel>().deleteIngredient(ingredient.id);
                if (mounted) Navigator.of(dialogContext).pop();
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
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
          content: Text(viewModel.ocrErrorMessage ?? '처리 중 오류가 발생했습니다.'), backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      await nav?.maybePop();
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('이미지 처리 중 오류 발생: $e'), backgroundColor: Colors.red));
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
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('작업이 실패했습니다. 다시 시도해주세요.'), backgroundColor: Colors.red));
      }
    }
  }
}












