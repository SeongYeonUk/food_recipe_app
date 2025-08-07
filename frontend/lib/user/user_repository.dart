// frontend/lib/user/user_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class UserRepository {
  final String _baseUrl = "http://10.0.2.2:8080";

  /// 회원가입을 요청하는 메소드입니다.
  Future<bool> signUp(String uid, String password, String nickname) async {
    // [수정] API 경로는 동일합니다.
    final url = Uri.parse('$_baseUrl/api/auth/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid, // [수정] 서버가 요구하는 'uid' 키로 변경
          'password': password,
          'nickname': nickname,
        }),
      );

      // [수정] 백엔드가 이제 201 Created 코드를 보내므로, 성공 기준을 변경합니다.
      if (response.statusCode == 201) {
        print('회원가입 요청 성공: ${response.body}');
        return true;
      } else {
        print('회원가입 요청 실패: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('회원가입 중 클라이언트 오류 발생: $e');
      return false;
    }
  }

  /// 로그인을 요청하는 메소드입니다.
  Future<String?> login(String uid, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid, // [수정] 서버가 요구하는 'uid' 키로 변경
          'password': password,
        }),
      );

      // [수정] 백엔드가 이제 200 OK 코드를 보내므로, 성공 기준을 명확히 합니다.
      if (response.statusCode == 200) {
        final token = response.headers['authorization'];
        print('로그인 성공, 발급된 토큰: $token');
        return token;
      } else {
        print('로그인 요청 실패: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('로그인 중 클라이언트 오류 발생: $e');
      return null;
    }
  }
}



