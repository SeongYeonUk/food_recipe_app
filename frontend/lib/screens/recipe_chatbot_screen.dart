import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/basic_recipe_item.dart';
import '../models/ingredient_model.dart';
import '../services/chatbot_service.dart';

enum ChatMode { recommend, cooking }

enum RecipeInfoDisplay { time, calorie, price }

class RecipeChatbotScreen extends StatefulWidget {
  const RecipeChatbotScreen({super.key});

  @override
  State<RecipeChatbotScreen> createState() => _RecipeChatbotScreenState();
}

class _ChatMessage {
  final bool fromUser;
  final String text;
  final List<String> suggested;
  final List<String> matching;
  final List<BasicRecipeItem> recipes;
  final CookingResponse? cooking;
  final List<ExpiryRecommendation> expiry;
  final List<Ingredient> expiringItems;
  final int? timerDuration;
  final RecipeInfoDisplay recipeInfoDisplay;

  _ChatMessage({
    required this.fromUser,
    required this.text,
    this.suggested = const [],
    this.matching = const [],
    this.recipes = const [],
    this.cooking,
    this.expiry = const [],
    this.expiringItems = const [],
    this.timerDuration,
    this.recipeInfoDisplay = RecipeInfoDisplay.time,
  });
}

class _RecipeChatbotScreenState extends State<RecipeChatbotScreen> {
  final ChatbotService _service = ChatbotService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  final List<_ChatMessage> _messages = [];
  ChatMode _mode = ChatMode.recommend;
  bool _isSending = false;
  bool _isListening = false;
  bool _speechReady = false;
  bool _autoTtsEnabledForResponse = false;
  String? _selectedRecipeName;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initPlayer();
    // 초기 환영 메시지
    _messages.add(
      _ChatMessage(
        fromUser: false,
        text:
            '안녕하세요! 무엇을 도와드릴까요?\n예: "마늘 요리 추천해줘", "냉장고에 뭐 있어?", "대파 대체재료 알려줘"',
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final hasMic = await _ensureMicPermission();
    if (!hasMic) {
      setState(() => _speechReady = false);
      return;
    }
    final ok = await _speech.initialize();
    setState(() => _speechReady = ok);
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    await _player.setVolume(0.9);
  }

  Future<void> _stopTtsPlayback() async {
    try {
      await _player.stopPlayer();
    } catch (_) {
      // 이미 정지 상태일 수 있음
    }
  }

  Future<void> _startListening() async {
    if (!_speechReady || !await _ensureMicPermission()) {
      _showSnack('음성 인식 권한을 확인해 주세요.');
      return;
    }
    await _stopTtsPlayback(); // 재생 중이던 음성 출력 중단
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (res) {
        _inputController.text = res.recognizedWords;
        if (res.finalResult && res.recognizedWords.isNotEmpty) {
          _sendText(fromVoice: true);
        }
      },
    );
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }
    return true;
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  // 📨 메시지 전송 및 처리 핵심 로직
  Future<void> _sendText({bool fromVoice = false}) async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    _autoTtsEnabledForResponse = fromVoice || _isListening;

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(fromUser: true, text: text));
    });
    _inputController.clear();
    _stopListening();
    _scrollToBottom();

    // 1. 의도 파악을 위한 키워드 분석
    final isCookingIntent = _looksLikeCookingCommand(text);
    final isSelectionIntent = _looksLikeRecipeSelection(text);
    final isIngredientQuery = _looksLikeIngredientQuery(text);
    final isExpiringListRequest = _looksLikeExpiringListRequest(text);
    final isCalorieIntent = _looksLikeCalorieFilterRequest(text);
    final isPriceIntent = _looksLikePriceFilterRequest(text);
    final isSubstituteIntent = _looksLikeSubstituteRequest(text);

    // 요리 선택 시 이름 추출 ("오므라이스로 할게")
    if (isSelectionIntent) {
      _selectedRecipeName = _extractRecipeNameFromSelection(text);
    }
    // 재료 질문 시 이름 추출 ("오므라이스 재료 알려줘")
    if (isIngredientQuery) {
      final extracted = _extractRecipeNameFromIngredientQuery(text);
      if (extracted != null) _selectedRecipeName = extracted;
    }

    // 2. 어떤 API를 호출할지 결정
    // 대체재료 질문이거나, 추천 모드에서의 일반 대화는 recommend(실제로는 /ask) 호출
    bool shouldCallRecommend;
    if (isSubstituteIntent) {
      shouldCallRecommend = true;
    } else {
      shouldCallRecommend =
          !isExpiringListRequest &&
          !isSelectionIntent &&
          !isCookingIntent &&
          _mode == ChatMode.recommend;
    }

    // 요리 모드이거나, 요리 관련 명령(선택, 시작 등)인 경우
    final shouldCallCooking =
        !isExpiringListRequest &&
        !isSubstituteIntent &&
        ((_mode == ChatMode.cooking) || isCookingIntent || isSelectionIntent);

    final shouldCallExpiry =
        !isExpiringListRequest &&
        !isSubstituteIntent &&
        !isIngredientQuery &&
        _looksLikeExpiryRequest(text);
    final shouldCallExpiringList = isExpiringListRequest;

    final recipeInfoDisplay = isPriceIntent
        ? RecipeInfoDisplay.price
        : (isCalorieIntent
              ? RecipeInfoDisplay.calorie
              : RecipeInfoDisplay.time);

    final int beforeBotCount = _messages.length;

    try {
      // Case 1: 레시피 추천 or 대체재료 질문 (/ask)
      if (shouldCallRecommend) {
        String recommendText = text;
        // 재료 질문 시 맥락 유지를 위해 요리 이름 포함
        if (isIngredientQuery && _selectedRecipeName != null) {
          recommendText = '$_selectedRecipeName $text';
        }

        RecipeRecommendationResult? result = await _service.recommend(
          recommendText,
        );

        if (result != null) {
          // A. 챗봇 답변(message)이 온 경우 (대체재료, 잡담 등)
          if (result.message != null && result.recipes.isEmpty) {
            _addBotMessage(
              _ChatMessage(fromUser: false, text: result.message!),
            );
          }
          // B. 레시피 목록이 온 경우
          else {
            final summary = _buildRecommendationSummary(result);
            _addBotMessage(
              _ChatMessage(
                fromUser: false,
                text: summary,
                suggested: result.suggestedIngredients,
                matching: result.matchingIngredients,
                recipes: result.recipes,
                recipeInfoDisplay: recipeInfoDisplay,
              ),
            );
          }
        }
      }

      // Case 2: 냉장고 임박 재료 확인
      if (shouldCallExpiringList) {
        final items = await _service.fetchExpiringIngredients(withinDays: 7);
        final names = items.map((e) => e.name).toList();
        final summary = names.isEmpty
            ? '임박한 식재료를 찾지 못했어요.'
            : '${names.join(', ')}이 현재 유통기한 임박 식재료입니다.';
        _addBotMessage(
          _ChatMessage(fromUser: false, text: summary, expiringItems: items),
        );
      }

      // Case 3: 조리 명령 (/cooking)
      if (shouldCallCooking) {
        // 텍스트 보정 (선택 시 명확한 의도 전달)
        String cookingText = text;
        // 만약 "오므라이스로 할게"라고 했는데 _selectedRecipeName을 못 찾았다면, 텍스트 그대로 보냄

        final res = await _service.handleCooking(cookingText);

        if (res != null) {
          if (_isCookingResponseMeaningful(res)) {
            _addBotMessage(
              _ChatMessage(fromUser: false, text: res.message, cooking: res),
            );
          }

          // 서버의 ActionType에 따른 상태 변경
          if (res.actionType == 'START_COOKING') {
            setState(() {
              _mode = ChatMode.cooking;
              if (_selectedRecipeName != null) {
                // 선택된 요리 이름 업데이트 (필요시)
              }
            });
          } else if (res.actionType == 'FINISH') {
            setState(() {
              _mode = ChatMode.recommend;
              _selectedRecipeName = null; // 요리 끝났으니 선택 초기화
            });
          } else if (res.actionType == 'TIMER_START' &&
              res.timerSeconds != null) {
            final timerMessage =
                '타이머를 ${res.timerSeconds! ~/ 60}분 ${res.timerSeconds! % 60}초로 설정할게요.';
            _addBotMessage(
              _ChatMessage(
                fromUser: false,
                text: timerMessage,
                timerDuration: res.timerSeconds,
              ),
            );
          }
        }
      }

      // Case 4: 유통기한 추천 (단일 질문)
      if (shouldCallExpiry) {
        final expiryRes = await _service.recommendExpiry();
        if (expiryRes != null && expiryRes.recommendations.isNotEmpty) {
          final summary = _buildExpirySummary(expiryRes);
          _addBotMessage(
            _ChatMessage(
              fromUser: false,
              text: summary,
              expiry: expiryRes.recommendations,
            ),
          );
        }
      }

      // 응답이 하나도 없으면 에러 처리
      if (_messages.length == beforeBotCount) {
        // 봇 메시지가 추가되지 않음
        _addBotMessage(_botError('죄송해요, 요청을 처리하지 못했어요.'));
      }
    } catch (e) {
      print('Chat Error: $e');
      _addBotMessage(_botError('오류가 발생했어요: $e'));
    } finally {
      _autoTtsEnabledForResponse = false;
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  // --- Helper Methods ---

  String _buildRecommendationSummary(RecipeRecommendationResult r) {
    if (r.recipes.isEmpty && r.suggestedIngredients.isEmpty) {
      return '조건에 맞는 추천을 찾지 못했어요. 다른 재료나 시간을 말해보세요.';
    }
    final suggestPart = r.suggestedIngredients.isEmpty
        ? ''
        : '추천 재료: ${r.suggestedIngredients.join(', ')}';
    final matchPart = r.matchingIngredients.isEmpty
        ? ''
        : '냉장고 보유: ${r.matchingIngredients.join(', ')}';
    final recipePart = r.recipes.isEmpty
        ? ''
        : '추천 레시피 ${r.recipes.length}개를 찾았어요.';

    return [
      suggestPart,
      matchPart,
      recipePart,
    ].where((e) => e.isNotEmpty).join('\n');
  }

  String _buildExpirySummary(ExpiryRecommendationResult r) {
    final total = r.recommendations.length;
    final updated = r.recommendations.where((e) => e.updated).length;
    return '유통기한 추천 ${total}개 중 반영 $updated개';
  }

  // 키워드 분석 헬퍼들
  bool _looksLikeCookingCommand(String text) {
    final lower = text.toLowerCase();
    if (_looksLikeSubstituteRequest(lower)) return false; // 대체재료는 요리 명령 아님
    const keywords = [
      '타이머',
      '시작',
      '스텝',
      '단계',
      '조리',
      '요리',
      '다음',
      '이전',
      '순서',
      '멈춰',
      '중단',
      '여기까지',
      '그만',
    ];
    return keywords.any((k) => lower.contains(k));
  }

  bool _looksLikeRecipeSelection(String text) {
    final lower = text.toLowerCase();
    const markers = ['로 할게', '로 할께', '으로 할게', '으로 할께', '이걸로', '선택', '골라', '할래'];
    return markers.any((k) => lower.contains(k));
  }

  String? _extractRecipeNameFromSelection(String text) {
    final lower = text.toLowerCase();
    const markers = ['로 할게', '로 할께', '으로 할게', '으로 할께', '이걸로', '선택', '골라', '할래'];
    for (final marker in markers) {
      if (lower.contains(marker)) {
        final parts = lower.split(marker);
        if (parts.first.isNotEmpty) return parts.first.trim();
      }
    }
    return null;
  }

  bool _looksLikeIngredientQuery(String text) {
    final lower = text.toLowerCase();
    return lower.contains('재료') &&
        (lower.contains('알려') || lower.contains('뭐') || lower.contains('보여'));
  }

  String? _extractRecipeNameFromIngredientQuery(String text) {
    // "오므라이스 재료 알려줘" -> "오므라이스"
    if (text.contains('재료')) {
      final part = text.split('재료').first.trim();
      if (part.isNotEmpty) return part;
    }
    return null;
  }

  bool _looksLikeExpiryRequest(String text) =>
      text.contains('유통기한') && text.contains('추천');

  bool _looksLikeExpiringListRequest(String text) {
    final lower = text.toLowerCase();
    return (lower.contains('임박') || lower.contains('유통기한')) &&
        (lower.contains('뭐') || lower.contains('알려'));
  }

  bool _looksLikeCalorieFilterRequest(String text) =>
      text.contains('칼로리') || text.contains('kcal');
  bool _looksLikePriceFilterRequest(String text) =>
      text.contains('가격') || text.contains('원') || text.contains('비용');

  bool _looksLikeSubstituteRequest(String text) {
    final lower = text.toLowerCase();
    const keywords = ['대체', '대신', '없어', 'substitute'];
    return keywords.any((k) => lower.contains(k));
  }

  bool _isCookingResponseMeaningful(CookingResponse res) {
    return res.message.trim().isNotEmpty && !res.message.contains('이해하지 못했');
  }

  _ChatMessage _botError(String text) =>
      _ChatMessage(fromUser: false, text: text);

  void _addBotMessage(
    _ChatMessage message, {
    bool forceAutoTts = false,
  }) {
    setState(() {
      _messages.add(message);
    });

    final shouldAutoTts =
        (forceAutoTts || _autoTtsEnabledForResponse) &&
            !message.fromUser &&
            message.text.trim().isNotEmpty;

    if (shouldAutoTts) {
      _playTts(message.text);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTimerEnd() {
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(fromUser: false, text: '⏰ 타이머가 종료되었습니다! 다음 단계를 진행해 주세요.'),
      );
    });
    _playTts('타이머가 종료되었습니다.');
    _scrollToBottom();
  }

  Future<void> _playTts(String text) async {
    try {
      final bytes = await _service.synthesizeTts(text);
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/chatbot_tts.mp3');
      await file.writeAsBytes(bytes, flush: true);

      await _player.stopPlayer();
      await _player.startPlayer(fromURI: file.path);
    } catch (_) {}
  }

  Future<void> _startCookingByClick(BasicRecipeItem item) async {
    final res = await _service.startCookingById(item.recipeId);
    if (res != null) {
      setState(() {
        _mode = ChatMode.cooking;
        _selectedRecipeName = item.recipeNameKo;
        _messages.add(
          _ChatMessage(fromUser: false, text: res.message, cooking: res),
        );
      });
      _scrollToBottom();
    } else {
      _showSnack('조리 시작 실패');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피 챗봇'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          _buildFeatureRow(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildBubble(_messages[index]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('똑똑한 추천'),
            selected: _mode == ChatMode.recommend,
            onSelected: (_) => setState(() => _mode = ChatMode.recommend),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('요리 코파일럿'),
            selected: _mode == ChatMode.cooking,
            onSelected: (_) => setState(() => _mode = ChatMode.cooking),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow() {
    final features = _mode == ChatMode.recommend
        ? const ['유통기한/재고 조회', '레시피 랭킹', '유통기한 추천']
        : const ['조리 액션', '타이머 명령', '재료 매칭'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => Chip(
          label: Text(features[i]),
          avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
          backgroundColor: Colors.grey.shade100,
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: features.length,
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.fromUser;
    final bubbleColor = isUser ? Colors.teal.shade50 : Colors.white;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.text, style: const TextStyle(fontSize: 15)),
                if (!isUser && msg.cooking != null) ...[
                  const SizedBox(height: 8),
                  Text('액션: ${msg.cooking!.actionType}'),
                  if (msg.cooking!.timerSeconds != null)
                    Text('타이머: ${msg.cooking!.timerSeconds}초'),
                ],
                if (!isUser && msg.timerDuration != null) ...[
                  const SizedBox(height: 12),
                  _ChatTimer(
                    initialDuration: msg.timerDuration!,
                    onTimerEnd: _onTimerEnd,
                  ),
                  const SizedBox(height: 4),
                ],
                if (!isUser &&
                    (msg.suggested.isNotEmpty || msg.matching.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...msg.suggested.map(
                        (e) => _pill(e, Colors.blue.shade50, Colors.blue),
                      ),
                      ...msg.matching.map(
                        (e) =>
                            _pill('보유: $e', Colors.green.shade50, Colors.green),
                      ),
                    ],
                  ),
                ],
                if (!isUser && msg.recipes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildRecipeList(msg.recipes, msg.recipeInfoDisplay),
                ],
                if (!isUser && msg.expiringItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildExpiringList(msg.expiringItems),
                ],
                if (!isUser && msg.expiry.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '유통기한 추천',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: msg.expiry
                        .map(
                          (e) => Text(
                            '${e.name}: ${e.recommendedDate}${e.updated ? " (반영)" : ""}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (!isUser)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.volume_up, size: 20),
                      onPressed: () => _playTts(msg.text),
                      tooltip: '음성으로 듣기',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringList(List<Ingredient> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '유통기한 임박 식재료',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final ing = items[index];
              return SizedBox(
                width: 210,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ing.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '유통기한: ${DateFormat('yyyy.MM.dd').format(ing.expiryDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '용량/수량: ${ing.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ing.dDayText,
                            style: TextStyle(
                              fontSize: 12,
                              color: ing.dDayColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12)),
    );
  }

  Widget _buildRecipeList(
    List<BasicRecipeItem> recipes,
    RecipeInfoDisplay display,
  ) {
    String summaryText(String summary) {
      // 요약이 길 경우 첫 문장만 표시
      if (summary.contains('.')) {
        return summary.split('.').first.trim();
      } else if (summary.contains('/')) {
        return summary.split('/').first.trim();
      }
      return summary;
    }

    String infoText(BasicRecipeItem r) {
      switch (display) {
        case RecipeInfoDisplay.calorie:
          if (r.calorie.isEmpty) return '';
          final parsed = double.tryParse(r.calorie.replaceAll(',', ''));
          if (parsed != null) {
            final clean = parsed.toStringAsFixed(parsed % 1 == 0 ? 0 : 1);
            return '$clean kcal';
          }
          return r.calorie;
        case RecipeInfoDisplay.price:
          if (r.maxPriceKrw == null) return '';
          final formatted = NumberFormat(
            '#,###',
          ).format(r.maxPriceKrw!.round());
          return '최대 ${formatted}원';
        case RecipeInfoDisplay.time:
        default:
          return r.cookingTime;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('추천 레시피', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final r = recipes[index];
              final info = infoText(r);
              return SizedBox(
                width: 200,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.recipeNameKo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summaryText(r.summary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (info.isNotEmpty)
                          _pill(info, Colors.orange.shade50, Colors.orange),
                        const Spacer(),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => _startCookingByClick(r),
                              child: const Text('조리 시작'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.grey[700],
              ),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '레시피 추천이나 명령을 말하거나 입력하세요',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSending ? null : _sendText,
              child: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('전송'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTimer extends StatefulWidget {
  final int initialDuration;
  final VoidCallback onTimerEnd;

  const _ChatTimer({required this.initialDuration, required this.onTimerEnd});

  @override
  State<_ChatTimer> createState() => _ChatTimerState();
}

class _ChatTimerState extends State<_ChatTimer> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialDuration;
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        widget.onTimerEnd();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
      } else {
        _start();
      }
    });
  }

  void _reset() {
    setState(() {
      _isPaused = false;
      _remainingSeconds = widget.initialDuration;
      _start();
    });
  }

  String get _formattedTime {
    final min = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formattedTime,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _togglePause,
              child: Text(_isPaused ? '계속' : '중단'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _reset, child: const Text('재설정')),
          ],
        ),
      ],
    );
  }
}
