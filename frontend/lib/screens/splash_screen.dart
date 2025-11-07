// lib/user/splash_screen.dart (또는 해당 파일 경로)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ⭐ Provider 사용을 위해 추가
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/auth_status.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';
import '../viewmodels/recipe_viewmodel.dart'; // ⭐ RecipeViewModel 사용을 위해 추가
import '../viewmodels/refrigerator_viewmodel.dart'; // ⭐ RefrigeratorViewModel 사용을 위해 추가

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadData();
  }

  // [❗️수정] 이 함수 전체를 아래 코드로 교체하세요.
  void _checkLoginAndLoadData() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    // 1. 로그인 상태 확인 로직
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

        // [❗️수정] Recipe와 Refrigerator 데이터를 '병렬'로 '함께' 로드합니다.
        // (이 작업이 완료되어야 경합 조건이 해결됩니다)
        try {
          await Future.wait([
            context.read<RecipeViewModel>().loadInitialData(),
            context.read<RefrigeratorViewModel>().loadInitialData(),
          ]);
        } catch (e) {
          // 데이터 로딩 중 하나라도 실패하면 로그인 화면으로 보냅니다.
          print('스플래시 스크린 데이터 로딩 실패: $e');
          await storage.deleteAll();
          authStatus.logout();
          userModel.clear();
          if (mounted) Navigator.of(context).pushReplacementNamed('/start');
          return; // 함수 종료
        }

        // 모든 로딩이 성공한 후 `mounted`를 다시 확인하고 메인 화면으로 이동
        if (!mounted) return;
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
