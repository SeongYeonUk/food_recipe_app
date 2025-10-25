import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ⭐ Provider 사용을 위해 추가
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/auth_status.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';
import '../viewmodels/recipe_viewmodel.dart'; // ⭐ RecipeViewModel 사용을 위해 추가

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ⭐ [핵심 수정] 로그인 확인 후 데이터를 로드하도록 통합
    _checkLoginAndLoadData();
  }

  void _checkLoginAndLoadData() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    // 1. 로그인 상태 확인 로직 (기존 코드 유지)
    const storage = FlutterSecureStorage();
    final authStatus = AuthStatus();
    final userModel = UserModel();
    final userRepository = UserRepository();

    final accessToken = await storage.read(key: 'ACCESS_TOKEN');

    if (!mounted) return;

    if (accessToken != null) {
      authStatus.setToken(accessToken);
      final profileResponse = await userRepository.getMyProfile();

      if (profileResponse != null && profileResponse.statusCode == 200) {
        final profileBody = jsonDecode(utf8.decode(profileResponse.bodyBytes));
        userModel.loadFromMap(profileBody);

        // ⭐⭐⭐ [데이터 로딩] 로그인 성공 후 메인 화면 이동 전에 데이터 로드 ⭐⭐⭐
        // 이 코드가 RecipeViewModel의 loadInitialData()를 호출하여 초기 데이터를 로드합니다.
        await context.read<RecipeViewModel>().loadInitialData();

        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        // 토큰 유효성 검사 실패 (토큰 만료 등)
        await storage.deleteAll();
        authStatus.logout();
        userModel.clear();
        Navigator.of(context).pushReplacementNamed('/start');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/start');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PRIMARY_COLOR,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'asset/img/login_logo.png',
              width: MediaQuery.of(context).size.width / 2,
            ),
            const SizedBox(height: 16.0),
            const CircularProgressIndicator(color: INPUT_BG_COLOR),
          ],
        ),
      ),
    );
  }
}
