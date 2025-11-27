import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/basic_recipe_item.dart';
import '../services/chatbot_service.dart';

enum ChatMode { recommend, cooking }

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

  _ChatMessage({
    required this.fromUser,
    required this.text,
    this.suggested = const [],
    this.matching = const [],
    this.recipes = const [],
    this.cooking,
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    _speech.stop();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize();
    setState(() => _speechReady = ok);
  }

  Future<void> _startListening() async {
    if (!_speechReady) {
      _showSnack('음성 인식 권한을 확인해 주세요.');
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (res) {
        _inputController.text = res.recognizedWords;
        if (res.finalResult && res.recognizedWords.isNotEmpty) {
          _sendText();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(fromUser: true, text: text));
    });
    _inputController.clear();
    _stopListening();
    _scrollToBottom();

    try {
      if (_mode == ChatMode.recommend) {
        final result = await _service.recommend(text);
        if (result != null) {
          final summary = _buildRecommendationSummary(result);
          _messages.add(
            _ChatMessage(
              fromUser: false,
              text: summary,
              suggested: result.suggestedIngredients,
              matching: result.matchingIngredients,
              recipes: result.recipes,
            ),
          );
        } else {
          _messages.add(_botError('추천 결과를 불러오지 못했어요.'));
        }
      } else {
        final res = await _service.handleCooking(text);
        if (res != null) {
          _messages.add(_ChatMessage(fromUser: false, text: res.message, cooking: res));
          if (res.actionType == 'TIMER_START' && res.timerSeconds != null) {
            _startTimer(res.timerSeconds!);
          }
        } else {
          _messages.add(_botError('조리 세션과 통신에 실패했어요.'));
        }
      }
    } catch (_) {
      _messages.add(_botError('서버 통신 중 오류가 발생했어요.'));
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  String _buildRecommendationSummary(RecipeRecommendationResult r) {
    if (r.recipes.isEmpty && r.suggestedIngredients.isEmpty) {
      return '조건에 맞는 추천을 찾지 못했어요. 다른 재료나 시간을 말해보세요.';
    }
    final suggestPart = r.suggestedIngredients.isEmpty ? '' : '추천 키워드: ${r.suggestedIngredients.join(', ')}';
    final matchPart = r.matchingIngredients.isEmpty ? '' : '냉장고 보유: ${r.matchingIngredients.join(', ')}';
    final recipePart = r.recipes.isEmpty ? '' : '추천 레시피 ${r.recipes.length}개를 찾았어요.';
    return [suggestPart, matchPart, recipePart].where((e) => e.isNotEmpty).join(' · ');
  }

  _ChatMessage _botError(String text) {
    return _ChatMessage(fromUser: false, text: text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: seconds), () {
      if (mounted) {
        _showSnack('타이머 종료! 다음 단계를 진행해 주세요.');
      }
    });
    _showSnack('타이머 ${seconds ~/ 60}분 ${seconds % 60}초 시작');
  }

  Future<void> _playTts(String text) async {
    try {
      final bytes = await _service.synthesizeTts(text);
      if (bytes == null) {
        _showSnack('TTS를 가져오지 못했어요.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/chatbot_tts.mp3');
      await file.writeAsBytes(bytes, flush: true);
      await _player.stopPlayer();
      await _player.startPlayer(fromURI: file.path);
    } catch (_) {
      _showSnack('음성을 재생할 수 없어요.');
    }
  }

  Future<void> _startCookingByClick(BasicRecipeItem item) async {
    final res = await _service.startCookingById(item.recipeId);
    if (res != null) {
      setState(() {
        _messages.add(_ChatMessage(fromUser: false, text: res.message, cooking: res));
      });
      if (res.actionType == 'TIMER_START' && res.timerSeconds != null) {
        _startTimer(res.timerSeconds!);
      }
      _scrollToBottom();
    } else {
      _showSnack('조리 세션을 시작하지 못했어요.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildBubble(msg);
              },
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
    const features = [
      'STT 텍스트 분석',
      '유통기한/재고 조회',
      '대체 재료 매칭',
      '레시피 랭킹',
      '조리 세션',
      '타이머 명령',
    ];
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
                Text(
                  msg.text,
                  style: const TextStyle(fontSize: 15),
                ),
                if (!isUser && msg.cooking != null) ...[
                  const SizedBox(height: 8),
                  Text('액션: ${msg.cooking!.actionType}'),
                  if (msg.cooking!.timerSeconds != null)
                    Text('타이머: ${msg.cooking!.timerSeconds}초'),
                ],
                if (!isUser && (msg.suggested.isNotEmpty || msg.matching.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...msg.suggested.map((e) => _pill(e, Colors.blue.shade50, Colors.blue)),
                      ...msg.matching.map((e) => _pill('보유: $e', Colors.green.shade50, Colors.green)),
                    ],
                  ),
                ],
                if (!isUser && msg.recipes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildRecipeList(msg.recipes),
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

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12)),
    );
  }

  Widget _buildRecipeList(List<BasicRecipeItem> recipes) {
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
              return SizedBox(
                width: 200,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.recipeNameKo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(r.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const Spacer(),
                        Row(
                          children: [
                            if (r.cookingTime.isNotEmpty) _pill('${r.cookingTime}분', Colors.orange.shade50, Colors.orange),
                            const Spacer(),
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
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.grey[700]),
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
              child: _isSending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('전송'),
            ),
          ],
        ),
      ),
    );
  }
}
