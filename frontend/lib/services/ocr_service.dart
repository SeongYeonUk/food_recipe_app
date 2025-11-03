import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';

class OcrService {
  // Service Account credential placed in assets
  static const _credentialsPath = 'asset/my-recipe-app-ocr-2e84d27e91be.json';

  Future<List<String>> scanReceipt(File imageFile) async {
    try {
      final credentialsJson = await rootBundle.loadString(_credentialsPath);
      final credentials = ServiceAccountCredentials.fromJson(jsonDecode(credentialsJson));
      final client = await clientViaServiceAccount(credentials, [vision.VisionApi.cloudVisionScope]);
      final api = vision.VisionApi(client);

      final base64Image = base64Encode(await imageFile.readAsBytes());
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
      final response = await api.images.annotate(request);

      final text = response.responses?.firstOrNull?.fullTextAnnotation?.text ?? '';
      if (text.isEmpty) return [];

      final lines = text.split('\n');
      const exclude = [
        '마트', '영수증', '금액', '합계', '과세', '부가세', '승인', '카드', '현금', '항목', '수량',
        '결제', '교환', '환불', '전화', '주소', '거래', '면세', '공급가', '번호', '시간'
      ];

      return lines.map((s) => s.trim()).where((s) => s.isNotEmpty).where((s) {
        if (RegExp(r'^[0-9.,\-: /]+$').hasMatch(s)) return false;
        if (RegExp(r'^20\d{2}[./-]\d{1,2}[./-]\d{1,2}').hasMatch(s)) return false;
        if (RegExp(r'\d{2,}[,\.]?\d*원').hasMatch(s)) return false;
        if (s.contains(':')) return false;
        if (exclude.any((k) => s.contains(k))) return false;
        return true;
      }).map((s) {
        var t = s.replaceAll(RegExp(r'\s[0-9,.*#]+$'), '').trim();
        t = t.replaceAll(RegExp(r'\([^)]*\)$'), '').trim();
        return t;
      }).where((s) => s.length >= 2).toList();
    } catch (e) {
      debugPrint('Google Vision API Error: $e');
      throw Exception('영수증 OCR 처리 중 오류가 발생했습니다.');
    }
  }
}

