// 📁 lib/screens/refrigerator_screen.dart (record 패키지로 교체 완료)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import 'package:food_recipe_app/common/Component/custom_dialog.dart';
import 'package:food_recipe_app/common/api_client.dart';
import 'package:food_recipe_app/common/ingredient_helper.dart';
import 'package:food_recipe_app/models/ingredient_model.dart';
import 'package:food_recipe_app/models/voice_ingredient.dart';
import 'package:food_recipe_app/models/recipe_model.dart';
import 'package:food_recipe_app/screens/barcode_scan_page.dart';
import 'package:food_recipe_app/screens/community_screen.dart';
import 'package:food_recipe_app/screens/receipt_result_screen.dart';
import 'package:food_recipe_app/screens/recipe_detail_screen.dart';
import 'package:food_recipe_app/screens/recipe_recommendation_screen.dart';
import 'package:food_recipe_app/viewmodels/recipe_viewmodel.dart';
import 'package:food_recipe_app/viewmodels/refrigerator_viewmodel.dart';

enum _VoiceMode { ingredient, chatbot }

class RefrigeratorScreen extends StatefulWidget {
  const RefrigeratorScreen({Key? key}) : super(key: key);

  @override
  State<RefrigeratorScreen> createState() => _RefrigeratorScreenState();
}

class _RefrigeratorScreenState extends State<RefrigeratorScreen> {
  static const String _kAll = '전체';
  bool _recommendCollapsed = false;
  bool _useFallbackImage = false; // legacy flag, kept for safety
  int _recImageIndex = 0;
  List<String> get _recImageCandidates {
    final base = ApiClient.baseUrl;
    return [
      '$base/images/galbijjim.png',
      '$base/static/images/galbijjim.png',
      '$base/static.images/galbijjim.png',
      '$base/galbijjim.png',
      '$base/images/%EA%B0%88%EB%B9%84%EC%B0%9F.png',
      '$base/images/eggrice.jpeg',
    ];
  }

  bool _isSelectionMode = false;
  final Set<Ingredient> _selectedIngredients = {};
  String _selectedCategoryFilter = _kAll;
  final GlobalKey _addButtonKey = GlobalKey();
  bool _alertsExpanded = false;

  // --- 🎙️ [수정] flutter_sound -> record ---
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  _VoiceMode? _voiceMode;
  String? _tempFilePath;
  final String _backendUrl = "${ApiClient.baseUrl}/api/items/voice";
  final String _backendConfirmUrl =
      "${ApiClient.baseUrl}/api/items/voice/confirm";
  // --- 🎙️ [수정] ---

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _checkPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RefrigeratorViewModel>(
        context,
        listen: false,
      ).loadInitialData();
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

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
      description: '달큰한 양념의 부드럽게 갈비찜',
      ingredients: ['소갈비', '무', '당근', '감자', '대파', '간장', '설탕', '마늘'],
      instructions: [
        '소갈비는 찬물에 담가 핏물을 빼요.',
        '무, 당근, 감자를 큼직하게 썰어요.',
        '간장, 설탕, 다진 마늘 등으로 양념장을 만들어요.',
        '갈비를 한 번 삶아 불순물을 제거해요.',
        '냄비에 갈비, 야채, 양념장을 넣고 부드럽게 졸여요.',
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
                const Text(
                  "오늘은 '갈비찜' 어때요?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                AnimatedRotation(
                  turns: _recommendCollapsed ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () => setState(
                      () => _recommendCollapsed = !_recommendCollapsed,
                    ),
                  ),
                ),
              ],
            ),
            if (!_recommendCollapsed) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Image.network(
                    _recImageCandidates[_recImageIndex.clamp(
                      0,
                      _recImageCandidates.length - 1,
                    )],
                    fit: BoxFit.cover,
                    key: ValueKey(_recImageIndex),
                    errorBuilder: (context, error, stack) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted &&
                            _recImageIndex < _recImageCandidates.length - 1) {
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
                          userIngredients: viewModel.ingredients
                              .map((e) => e.name)
                              .toList(),
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

  // --- 🎙️ 음성 녹음 로직 (record 패키지) ---
  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print('마이크 권한이 거부되었습니다.');
    }
  }

  void _handleVoiceInput() async {
    await _toggleVoiceRecording(_VoiceMode.ingredient);
  }

  void _handleChatbotVoiceInput() async {
    await _toggleVoiceRecording(_VoiceMode.chatbot);
  }

  Future<void> _toggleVoiceRecording(_VoiceMode mode) async {
    if (_isRecording) {
      await _stopRecordingAndSend();
    } else {
      await _startRecording(mode);
    }
  }

  Future<void> _startRecording(_VoiceMode mode) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();

        // 👇 [수정] 매번 새로운 파일명을 생성합니다 (타임스탬프 이용)
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        _tempFilePath = '${tempDir.path}/voice_$timestamp.wav';

        print('>>> [녹음 시작] 파일 경로: $_tempFilePath');

        _voiceMode = mode;

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _tempFilePath!,
        );

        setState(() => _isRecording = true);

        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              mode == _VoiceMode.ingredient ? '식재료 듣는 중... 말씀이 끝나면 전송을 눌러주세요' : '챗봇 듣는 중... 말씀이 끝나면 전송을 눌러주세요',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 30),
            action: SnackBarAction(
              label: '전송',
              textColor: Colors.white,
              onPressed: () => _stopRecordingAndSend(),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요합니다.')),
        );
      }
    } catch (e) {
      print('!!! [오류] 녹음 시작 실패: $e');
      setState(() => _isRecording = false);
    }
  }

  // 🎙️ 녹음 중지 및 모드별 전송
  Future<void> _stopRecordingAndSend() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    const storage = FlutterSecureStorage();
    final String? accessToken = await storage.read(key: 'ACCESS_TOKEN');

    if (accessToken == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (_tempFilePath == null) return;
      final audioFile = File(_tempFilePath!);

      if (!await audioFile.exists() || await audioFile.length() < 100) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('녹음이 너무 짧습니다. 다시 시도해주세요.')),
        );
        return;
      }

      final mode = _voiceMode ?? _VoiceMode.chatbot;
      if (mode == _VoiceMode.ingredient) {
        await _sendIngredientAudio(scaffoldMessenger, accessToken, audioFile);
      } else {
        await _sendChatbotAudio(scaffoldMessenger, accessToken, audioFile);
      }
    } catch (e) {
      print("오류 발생: $e");
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (_tempFilePath != null) {
        File(_tempFilePath!).delete().catchError((_) => null);
      }
      _voiceMode = null;
      _tempFilePath = null;
    }
  }

  Future<void> _sendIngredientAudio(
    ScaffoldMessengerState scaffoldMessenger,
    String accessToken,
    File audioFile,
  ) async {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('식재료 인식 중...'),
        duration: Duration(seconds: 2),
      ),
    );

    final response = await http.post(
      Uri.parse(_backendUrl),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Authorization': 'Bearer $accessToken',
      },
      body: await audioFile.readAsBytes(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> rawList = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final ingredients = rawList
          .map((e) => VoiceIngredient.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.name.isNotEmpty)
          .toList();

      if (ingredients.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('인식된 식재료가 없습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final selected = await _showVoiceIngredientSelector(ingredients);
      if (selected == null || selected.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('선택된 항목이 없습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final ok = await _confirmSelectedIngredients(selected, accessToken);
      if (ok) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('식재료가 추가됐어요!'),
            backgroundColor: Colors.green,
          ),
        );
        await Provider.of<RefrigeratorViewModel>(context, listen: false).fetchAllIngredients();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('등록에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print("식재료 음성 인식 실패: ${response.statusCode} / ${response.body}");
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('식재료 인식 실패 (네트워크 오류)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendChatbotAudio(
    ScaffoldMessengerState scaffoldMessenger,
    String accessToken,
    File audioFile,
  ) async {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('챗봇 분석 중...'),
        duration: Duration(seconds: 2),
      ),
    );

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/api/chatbot/audio'),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';
    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print(">>> [서버 응답] 상태코드: ${response.statusCode}");
    print(">>> [서버 응답] 내용: ${utf8.decode(response.bodyBytes)}");
    _handleServerResponse(response);
  }

  // 📦 [만능 응답 처리기] 서버 응답이 레시피인지, 챗봇 대화인지 구분해서 처리
  // 📦 [수정됨] 만능 응답 처리 함수 (에러 방지 강화)
  void _handleServerResponse(http.Response response) {
    print("🔵 [서버 응답 도착] 코드: ${response.statusCode}");

    try {
      // 1. 한글 깨짐 방지 디코딩
      String responseBody = utf8.decode(response.bodyBytes);
      print("📦 내용: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseBody);

        // ----------------------------------------------------
        // CASE A: 답변(message)이 있는 경우 (우선순위 1등)
        // ----------------------------------------------------
        if (jsonResponse.containsKey('message')) {
          final String message = jsonResponse['message'];
          final String actionType = jsonResponse['actionType'] ?? "SPEAK";

          // UI 갱신
          _processAction(actionType, message, jsonResponse);
          return;
        }

        // ----------------------------------------------------
        // CASE B: 레시피 추천 목록(recipes)이 온 경우
        // ----------------------------------------------------
        if (jsonResponse.containsKey('recipes')) {
          print("🍳 레시피 목록 발견!");
          // TODO: 레시피 화면으로 이동하는 코드 작성
          // Navigator.push(...);
          return;
        }

        // ----------------------------------------------------
        // CASE C: 냉장고 재료(items)가 온 경우
        // ----------------------------------------------------
        if (jsonResponse.containsKey('items')) {
          // TODO: 재료 목록 갱신
          return;
        }
      } else {
        print("❌ 서버 에러 발생: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 파싱 에러: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("앱 오류: $e")));
    }
  }

  // 🕹️ 액션 처리기 (분리함)
  void _processAction(
    String actionType,
    String message,
    Map<String, dynamic> json,
  ) {
    print("🤖 액션 실행: $actionType");

    switch (actionType) {
      case 'START_COOKING':
        _showChatDialog(message, isCookingMode: true);
        break;
      case 'TIMER_START':
        int seconds = json['timerSeconds'] ?? 180;
        _startTimer(seconds);
        _showChatDialog(message);
        break;
      case 'FINISH':
        _showChatDialog(message);
        break;
      case 'SPEAK':
      default:
        _showChatDialog(message); // 대체재료 답변은 여기서 뜹니다!
        break;
    }
  }

  // 💬 챗봇 말풍선 (수정됨: isCookingMode 파라미터 추가)
  // 💬 챗봇 말풍선 (isCookingMode 파라미터 추가됨)
  void _showChatDialog(String message, {bool isCookingMode = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // 조리 모드일 때는 배경색을 약간 초록색으로 바꿔서 구분감 주기
        backgroundColor: isCookingMode ? Colors.green[50] : Colors.white,
        title: Row(
          children: [
            Icon(
              isCookingMode ? Icons.soup_kitchen : Icons.smart_toy_outlined,
              color: isCookingMode ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(isCookingMode ? "조리 모드" : "AI 셰프"),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // ⏰ 타이머 함수
  void _startTimer(int seconds) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("⏱️ $seconds초 타이머가 시작되었습니다!"),
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) _showChatDialog("⏰ 타이머가 종료되었습니다!");
    });
  }

  Future<List<VoiceIngredient>?> _showVoiceIngredientSelector(
    List<VoiceIngredient> items,
  ) async {
    return showDialog<List<VoiceIngredient>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('추출된 식재료를 선택하세요'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: items
                      .map(
                        (item) => CheckboxListTile(
                          value: item.selected,
                          onChanged: (value) =>
                              setState(() => item.selected = value ?? false),
                          title: Text(item.name),
                          subtitle: Text(
                            [
                              if (item.category != null &&
                                  item.category!.isNotEmpty)
                                item.category!,
                              '수량: ${item.quantity}${item.unit ?? ''}',
                              if (item.expirationDate != null &&
                                  item.expirationDate!.isNotEmpty)
                                '유통기한: ${item.expirationDate}',
                            ].join(' / '),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final selected = items.where((e) => e.selected).toList();
                    Navigator.of(dialogContext).pop(selected);
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmSelectedIngredients(
    List<VoiceIngredient> selected,
    String accessToken,
  ) async {
    try {
      final response = await http.post(
        // 👇 [수정 1] 챗봇(/ask)이 아니라, 재료 저장 API 주소로 보내야 합니다!
        Uri.parse('${ApiClient.baseUrl}/api/items/voice/confirm'),

        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        // 재료 리스트 JSON 변환 (이건 맞습니다)
        body: jsonEncode(selected.map((e) => e.toJson()).toList()),
      );

      // 👇 [수정 2] 성공 여부를 명확히 리턴해야 합니다.
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ 재료 등록 성공");
        return true;
      } else {
        print("❌ 재료 등록 실패: ${response.body}");
        return false;
      }
    } catch (e) {
      print('음성 식재료 등록 예외 발생: $e');
      return false;
    }
  }

  // 📨 텍스트 전송 함수 (채팅창 '전송' 버튼 연결)
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 키보드 내리기
    FocusScope.of(context).unfocus();

    const storage = FlutterSecureStorage();
    final String? accessToken = await storage.read(key: 'ACCESS_TOKEN');

    try {
      print("🚀 텍스트 전송: $text");

      final response = await http.post(
        // 👇 [중요] 주소를 '/ask'로 하거나, 백엔드 수정본을 믿고 '/recommend'를 써도 됨.
        // 하지만 '/ask'가 가장 안전합니다.
        Uri.parse('${ApiClient.baseUrl}/api/chatbot/ask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'sttText': text}),
      );

      // 👇👇👇 [핵심] 여기서도 '만능 처리기'를 불러줘야 에러가 안 납니다! 👇👇👇
      _handleServerResponse(response);
    } catch (e) {
      print("에러 발생: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("에러: $e")));
    }
  }

  // --- 🎙️ 음성 로직 끝 ---

  //
  // --- ⬇️ 이하 UI --- ⬇️
  //

  Widget _buildRecommendationCard(RefrigeratorViewModel viewModel) {
    final expiringCount = viewModel.urgentIngredients.length;
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
                        const Text(
                          "오늘은 '된장찌개' 어때요?",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "현재 냉장고의 유통기한 임박 식재료는 '${expiringCount}개' 입니다.",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
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
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Icon(Icons.add, size: 32, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryAlerts(RefrigeratorViewModel viewModel) {
    final urgent = viewModel.ingredients.where((i) => i.dDay <= 3).toList();
    final soon = viewModel.ingredients
        .where((i) => i.dDay > 3 && i.dDay <= 7)
        .toList();
    if (urgent.isEmpty && soon.isEmpty) return const SizedBox.shrink();

    if (!_alertsExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            _buildAlertChip(
              '위험 ',
              Colors.red,
              onTap: () => _showAlertsBottomSheet(urgent, soon),
            ),
            const SizedBox(width: 8),
            _buildAlertChip(
              '주의 ',
              Colors.orange,
              onTap: () => _showAlertsBottomSheet(urgent, soon),
            ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.12),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            IngredientHelper.getImagePath(
                              ing.category,
                              ing.iconIndex,
                            ),
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ing.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                                Text(
                                  ing.dDayText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.1,
                                    color: ing.dDayColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
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
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
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

  Widget _buildAlertChip(
    String text,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
            ),
          ],
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
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
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
    final categoriesToShow = _selectedCategoryFilter == _kAll
        ? viewModel.categories
        : [_selectedCategoryFilter];
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final category = categoriesToShow[index];
        return _buildSingleCategorySection(viewModel, category);
      }, childCount: categoriesToShow.length),
    );
  }

  Widget _buildSingleCategorySection(
    RefrigeratorViewModel viewModel,
    String category,
  ) {
    final ingredients = viewModel.ingredientsByCategory[category] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Image.asset(
                  IngredientHelper.getImagePathForCategory(category),
                  width: 36,
                  height: 36,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ingredients.isEmpty
                  ? const SizedBox(
                      height: 80,
                      child: Center(
                        child: Text(
                          '재료 없음',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) => _buildIngredientItem(
                        context,
                        viewModel,
                        ingredients[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(
    BuildContext context,
    RefrigeratorViewModel viewModel,
    Ingredient ingredient,
  ) {
    final isSelected = _selectedIngredients.contains(ingredient);
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          if (mounted) {
            setState(() {
              if (isSelected) {
                _selectedIngredients.remove(ingredient);
                if (_selectedIngredients.isEmpty) _isSelectionMode = false;
              } else {
                _selectedIngredients.add(ingredient);
              }
            });
          }
        } else {
          _showIngredientDetailDialog(ingredient);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode && mounted) {
          setState(() {
            _isSelectionMode = true;
            _selectedIngredients.add(ingredient);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  IngredientHelper.getImagePath(
                    ingredient.category,
                    ingredient.iconIndex,
                  ),
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child:
                      IngredientHelper.getWarningIcon(ingredient.dDay) ??
                      const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (_) {
                final int d = ingredient.dDay;
                Color? bg;
                Color fg = Colors.black87;
                if (d <= 3) {
                  bg = const Color(0xFFFFE5E0);
                } else if (d <= 7) {
                  bg = const Color(0xFFFFF0E0);
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(color: fg),
                          child: label,
                        ),
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
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
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
              child: Text(
                "레시피 검색(${_selectedIngredients.length})",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIngredients.clear();
                  });
                }
              },
              child: const Text("선택취소"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RefrigeratorViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.refrigerators.isEmpty) {
          return Scaffold(
            appBar: null,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (viewModel.errorMessage != null) {
          return Scaffold(
            appBar: null,
            body: Center(child: Text(viewModel.errorMessage!)),
          );
        }
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: null,
          body: SafeArea(
            top: true,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildRecommendationCardNew(viewModel),
                ),
                SliverToBoxAdapter(
                  child: _buildCategoryFiltersWithButton(viewModel),
                ),
                SliverToBoxAdapter(child: _buildExpiryAlertsCompact(viewModel)),
                _buildCategorySections(viewModel),
              ],
            ),
          ),
          bottomNavigationBar: _isSelectionMode
              ? _buildSelectionBottomBar()
              : _buildRefrigeratorSelector(viewModel),
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
              style: TextStyle(
                color: isSelected ? Colors.teal : Colors.grey[700],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExpiryAlertsCompact(RefrigeratorViewModel viewModel) {
    final urgent = viewModel.ingredients.where((i) => i.dDay <= 3).toList();
    final soon = viewModel.ingredients
        .where((i) => i.dDay > 3 && i.dDay <= 7)
        .toList();
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
                          const Text(
                            '유통기한 임박 식재료',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
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

  Widget _buildAlertListSection(
    String title,
    Color color,
    List<Ingredient> list,
  ) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          IngredientHelper.getImagePath(
                            ing.category,
                            ing.iconIndex,
                          ),
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ing.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                ing.dDayText,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.1,
                                  color: ing.dDayColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext buildContext) {
    final viewModel = Provider.of<RefrigeratorViewModel>(
      context,
      listen: false,
    );
    _cancelSelection();
    final renderBox =
        _addButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    showGeneralDialog(
      context: buildContext,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(
        buildContext,
      ).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return Stack(
              children: [
                Positioned(
                  top: offset.dy + size.height - 10,
                  right:
                      MediaQuery.of(context).size.width -
                      offset.dx -
                      size.width,
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

  Widget _buildMenuCard(
    BuildContext dialogContext,
    RefrigeratorViewModel viewModel,
  ) {
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
                text: '음성 입력(식재료)',
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
                        showAddDialog:
                            ({
                              required BuildContext context,
                              String? initialName,
                            }) async {
                              await _showIngredientDialog(
                                context,
                                viewModel,
                                null,
                                initialName: initialName,
                              );
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

  Widget _buildOptionItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
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
            Image.asset(
              IngredientHelper.getImagePath(
                ingredient.category,
                ingredient.iconIndex,
              ),
              width: 28,
              height: 28,
            ),
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
            Text(
              "유통기한: ${DateFormat('yyyy.MM.dd').format(ingredient.expiryDate)}",
            ),
            Row(
              children: [
                Text(
                  "남은 d-day: ${ingredient.dDayText}",
                  style: TextStyle(
                    color: ingredient.dDayColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                IngredientHelper.getWarningIcon(ingredient.dDay) ??
                    const SizedBox.shrink(),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("닫기"),
          ),
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: Text("'${ingredient.name}'를 삭제할까요?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await context.read<RefrigeratorViewModel>().deleteIngredient(
                  ingredient.id,
                );
                if (mounted) Navigator.of(dialogContext).pop();
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showIngredientDialog(
                context,
                context.read<RefrigeratorViewModel>(),
                ingredient,
              );
            },
            child: const Text("변경"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageAndScan(
    BuildContext context,
    RefrigeratorViewModel viewModel,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final NavigatorState? nav = Navigator.maybeOf(context, rootNavigator: true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (!mounted || image == null) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final success = await viewModel.startOcrScan(File(image.path));
      if (!mounted) return;
      await nav?.maybePop();
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
            content: Text(viewModel.ocrErrorMessage ?? '처리 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      await nav?.maybePop();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('이미지 처리 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      final success = ingredient == null
          ? await viewModel.addIngredient(result)
          : await viewModel.updateIngredient(result);
      if (!mounted) return;
      if (!success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('작업이 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
