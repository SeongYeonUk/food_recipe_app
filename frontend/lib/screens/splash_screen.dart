// lib/screens/splash_screen.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/auth_status.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 1500));

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
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        // ==========================================================
        // ▼▼▼ (핵심 수정) forceLogout() 대신 직접 처리합니다. ▼▼▼
        // ==========================================================

        // 1. 저장소에 있는 모든 토큰 정보를 삭제합니다.
        await storage.deleteAll();

        // 2. 앱의 전역 로그인 상태를 초기화합니다.
        authStatus.logout();
        userModel.clear();

        // 3. 시작 화면으로 이동시킵니다.
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
            const CircularProgressIndicator(
              color: INPUT_BG_COLOR,
            ),
          ],
        ),
      ),
    );
  }
}


