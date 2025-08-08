// frontend/lib/user/user_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class UserRepository {
  final String _baseUrl = "http://10.0.2.2:8080";

  Future<http.Response> signUp(String uid, String password, String nickname, String passwordConfirm) async {
    final url = Uri.parse('$_baseUrl/api/auth/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'uid': uid,
        'password': password,
        'nickname': nickname,
        'passwordConfirm': passwordConfirm,
      }),
    );
    return response;
  }

  Future<String?> login(String uid, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final token = response.headers['authorization'];
        return token;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}