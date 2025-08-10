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

  Future<http.Response> login(String uid, String password) async {
    return await _apiClient.post(
      '/api/auth/login',
      body: {
        'uid': uid,
        'password': password,
      },
    );
  }

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
