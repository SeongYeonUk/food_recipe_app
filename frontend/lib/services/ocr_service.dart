import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';

class OcrService {
  // asset 폴더에 있는 JSON 키 파일의 전체 경로
  static const _credentialsPath = 'asset/my-recipe-app-ocr-2e84d27e91be.json';

  Future<List<String>> scanReceipt(File imageFile) async {
    try {
      // 1. API 호출 부분
      final credentialsJson = await rootBundle.loadString(_credentialsPath);
      final credentials = ServiceAccountCredentials.fromJson(jsonDecode(credentialsJson));
      final scopes = [vision.VisionApi.cloudVisionScope];
      final client = await clientViaServiceAccount(credentials, scopes);
      final visionApi = vision.VisionApi(client);
      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);
      final request = vision.BatchAnnotateImagesRequest.fromJson({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'}
            ]
          }
        ]
      });
      final response = await visionApi.images.annotate(request);

      // 2. 응답에서 텍스트 추출
      final List<String> items = [];
      if (response.responses != null && response.responses!.isNotEmpty) {
        final fullText = response.responses![0].fullTextAnnotation?.text;
        if (fullText != null) {
          items.addAll(fullText.split('\n'));
        }
      }

      if (items.isEmpty) {
        throw Exception('이미지에서 텍스트를 추출하지 못했습니다.');
      }

      // --- ▼▼▼ [최종 강화] 여기서부터 필터링 로직 V5가 시작됩니다 ▼▼▼ ---

      const List<String> exclusionKeywords = [
        '마트', '편의점', '영수증', '금액', '합계', '과세', '부가세',
        '할인', '포인트', '카드', '승인', '대표', '품목', '단가', '수량',
        '결제', '교환', '환불', '전화', '주소', '(주)', '매출전표', '세액',
        '면세', '물품', '금회', '잔액', '거스름', '공급가액', '품명', '상품명',
        '판매', '매일', '계산대', '금액', '일시불', '개월', '고객용', '번호', '일시'
      ];

      final List<String> filteredItems = [];
      for (var item in items) {
        var processedItem = item.trim();

        // [신규] 콜론(:)이 포함된 라인은 정보성 텍스트이므로 제외 (예: "카드번호:", "승인일시:")
        if (processedItem.contains(':')) {
          continue;
        }

        // [강화] "2025-" 또는 "2025." 로 시작하는 날짜/시간 정보 제외
        if (RegExp(r'^20\d{2}[-.]').hasMatch(processedItem)) {
          continue;
        }

        // --- (이하 V4 필터링 로직과 동일) ---
        if (RegExp(r'(시|구|동|읍|면|리|로|길)\s').hasMatch(processedItem) ||
            RegExp(r'\d{1,4}-\d{1,4}$').hasMatch(processedItem)) {
          continue;
        }
        if (RegExp(r'\d{2,}-\d{2,}-\d{4,}').hasMatch(processedItem) ||
            RegExp(r'\d{4,}-\d{4,}').hasMatch(processedItem)) {
          continue;
        }
        if (RegExp(r'\d{8,}').hasMatch(processedItem)) {
          continue;
        }
        processedItem = processedItem.replaceAll(RegExp(r'^\d{1,2}\s'), '').trim();
        if (processedItem.length < 2 ||
            RegExp(r'^[0-9,.\s/:-]+$').hasMatch(processedItem) ||
            RegExp(r'^[-=*_]+$').hasMatch(processedItem)) {
          continue;
        }
        if (exclusionKeywords.any((keyword) => processedItem.contains(keyword)) ||
            processedItem.contains('/')) {
          continue;
        }
        if (processedItem.toUpperCase().startsWith('Q:')) {
          continue;
        }
        processedItem = processedItem.replaceAll(RegExp(r'\s[0-9,.*#]+$'), '').trim();
        if (processedItem.startsWith('*') || processedItem.startsWith('#')) {
          continue;
        }
        processedItem = processedItem.replaceAll(RegExp(r'\([^)]*\)$'), '').trim();
        if(processedItem.isNotEmpty) {
          filteredItems.add(processedItem);
        }
      }
      // --- ▲▲▲ 필터링 로직 V5 끝 ▲▲▲ ---

      return filteredItems;

    } catch (e) {
      debugPrint('Google Vision API Error: $e');
      throw Exception('Google Vision API 요청 중 오류가 발생했습니다.');
    }
  }
}