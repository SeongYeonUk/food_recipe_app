// lib/common/api_client.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p; // path 패키지 import 추가

class ApiClient {
  final String baseUrl = "http://10.0.2.2:8080"; // Android 에뮬레이터 기준
  //final String baseUrl = "http://192.168.0.25:8080";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() async {
    return await _storage.read(key: 'ACCESS_TOKEN');
  }

  // [솔루션] Presigned URL을 사용하여 이미지를 업로드하는 새로운 방식의 함수입니다.
  Future<String?> uploadImage(File imageFile) async {
    final token = await _getAccessToken();

    // 1. 파일 이름만 추출합니다. (예: image_picker_...jpg)
    final fileName = p.basename(imageFile.path);

    try {
      // 2. 백엔드에 "허가증(Presigned URL) 발급"을 요청합니다.
      final presignedUrlResponse = await http.get(
        Uri.parse('$baseUrl/api/images/upload-url?fileName=$fileName'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (presignedUrlResponse.statusCode != 200) {
        print('Presigned URL 발급 실패: ${presignedUrlResponse.body}');
        return null;
      }

      final String presignedUrl = presignedUrlResponse.body;

      // 3. 발급받은 허가증을 사용하여, 이미지를 AWS S3에 직접 업로드합니다.
      final imageBytes = await imageFile.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(presignedUrl),
        headers: {
          'Content-Type': 'image/jpeg', // 이미지 타입에 맞게 설정 (필요시 동적으로 변경)
        },
        body: imageBytes,
      );

      if (uploadResponse.statusCode == 200) {
        // 4. 업로드 성공 시, 허가증 URL에서 '?' 앞부분(실제 저장된 URL)만 잘라서 반환합니다.
        final finalImageUrl = presignedUrl.split('?')[0];
        return finalImageUrl;
      } else {
        print('S3에 직접 업로드 실패: ${uploadResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('이미지 업로드 과정 중 예외 발생: $e');
      return null;
    }
  }

  Future<http.Response> get(String path) async {
    final token = await _getAccessToken();
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final token = await _getAccessToken();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final token = await _getAccessToken();
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _getAccessToken();
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
