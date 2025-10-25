// frontend/lib/user/user_repository.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

import 'dart:convert'; // print 문에서 한글 깨짐 방지를 위해 추가
import 'package:http/http.dart' as http;
import 'package:food_recipe_app/common/api_client.dart';
import 'package:food_recipe_app/main.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<http.Response> signUp(String uid, String password, String nickname, String passwordConfirm) async {
    return await _apiClient.post(
      '/api/auth/signup',
      body: {
        'uid': uid,
        'password': password,
        'nickname': nickname,
        'passwordConfirm': passwordConfirm,
      },
    );
  }

  // =========================================================================
  // ▼▼▼ 바로 이 login 메서드에 디버깅 코드를 추가했습니다 ▼▼▼
  // =========================================================================
  Future<http.Response> login(String uid, String password) async {
    // 1. 요청을 보내기 직전에 콘솔에 로그를 남깁니다.
    print(">>> 백엔드로 로그인 요청 보냄 -> UID: $uid");

    final response = await _apiClient.post(
      '/api/auth/login',
      body: {
        'uid': uid,
        'password': password,
      },
    );

    // 2. 응답을 받은 직후, 가장 중요한 정보인 '상태 코드'와 '응답 내용'을 콘솔에 남깁니다.
    print("<<< 백엔드로부터 응답 받음 -> 상태 코드: ${response.statusCode}");
    // 한글 오류 메시지가 깨지지 않도록 utf8.decode()를 사용합니다.
    print("<<< 백엔드로부터 응답 받음 -> 응답 내용: ${utf8.decode(response.bodyBytes)}");

    return response;
  }
  // =========================================================================

  Future<http.Response?> getMyProfile() async {
    try {
      return await _apiClient.get('/api/me');
    } on Exception catch (e) {
      if (e.toString().contains('401')) {
        forceLogout();
      }
      return null;
    }
  }

  Future<http.Response?> deleteAccount() async {
    try {
      return await _apiClient.delete('/api/me');
    } on Exception catch (e) {
      if (e.toString().contains('401')) {
        forceLogout();
      }
      return null;
    }
  }
}
