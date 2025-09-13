/// frontend/lib/common/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._privateConstructor();
  static final ApiClient _instance = ApiClient._privateConstructor();
  factory ApiClient() {
    return _instance;
  }

  final String baseUrl = "http://10.210.137.109:8080"; // ** 본인 PC의 IP 주소로 설정 **
  final storage = const FlutterSecureStorage();

  Future<Map<String, String>> getHeaders() async {
    final token = await storage.read(key: 'ACCESS_TOKEN');
    if (token != null) {
      return {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
    } else {
      return {'Content-Type': 'application/json; charset=UTF-8'};
    }
  }

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);
    handleUnauthorized(response);
    return response;
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await getHeaders();
    final encodedBody = body != null ? jsonEncode(body) : null;
    final response = await http.post(url, headers: headers, body: encodedBody);
    handleUnauthorized(response);
    return response;
  }

  // [추가] PUT 메소드
  Future<http.Response> put(String path, {Object? body}) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await getHeaders();
    final encodedBody = body != null ? jsonEncode(body) : null;
    final response = await http.put(url, headers: headers, body: encodedBody);
    handleUnauthorized(response);
    return response;
  }

  Future<http.Response> delete(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await getHeaders();
    final response = await http.delete(url, headers: headers);
    handleUnauthorized(response);
    return response;
  }

  void handleUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('401 Unauthorized');
    }
  }
}
