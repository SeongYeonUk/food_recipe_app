import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:food_recipe_app/common/component/custom_text_form.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/auth_status.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final UserRepository userRepository = UserRepository();
  final AuthStatus authStatus = AuthStatus();
  final UserModel userModel = UserModel();

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final uid = idController.text;
    final password = passwordController.text;

    if (uid.isEmpty || password.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    final loginResponse = await userRepository.login(uid, password);

    if (mounted) {
      if (loginResponse.statusCode == 200) {
        // --- 1. 로그인 성공 및 토큰 저장 ---
        final loginBody = jsonDecode(utf8.decode(loginResponse.bodyBytes));
        final accessToken = loginBody['accessToken'];
        final refreshToken = loginBody['refreshToken'];

        if (accessToken == null || refreshToken == null) {
          // 혹시 모를 예외 처리
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('토큰 처리 중 오류가 발생했습니다.')));
          return;
        }

        const storage = FlutterSecureStorage();
        await storage.write(key: 'ACCESS_TOKEN', value: accessToken);
        await storage.write(key: 'REFRESH_TOKEN', value: refreshToken);
        authStatus.setToken(accessToken);


        // --- 2. (핵심 추가) 저장된 토큰으로 내 정보(프로필) 요청하기 ---
        // ApiClient는 이제 헤더에 자동으로 토큰을 넣어줄 것입니다.
        final profileResponse = await userRepository.getMyProfile();

        if (profileResponse != null && profileResponse.statusCode == 200) {
          // --- 3. 내 정보 로딩 성공 시 UserModel 업데이트 ---
          final profileBody = jsonDecode(utf8.decode(profileResponse.bodyBytes));

          // 백엔드에서 {"uid": "...", "nickname": "..."} 형태로 응답한다고 가정
          userModel.loadFromMap(profileBody);

          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('${userModel.nickname}님 환영합니다!')),
          );

          // --- 4. 모든 작업 완료 후 메인 화면으로 이동 ---
          Navigator.of(context).pushReplacementNamed('/main');

        } else {
          // 프로필 로딩 실패 시 (이런 경우는 거의 없지만, 예외 처리)
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('사용자 정보를 불러오는 데 실패했습니다.')));
        }
      } else {
        // 로그인 자체를 실패했을 때
        final errorBody = jsonDecode(utf8.decode(loginResponse.bodyBytes));
        final errorMessage = errorBody['message'] ?? '아이디 또는 비밀번호가 일치하지 않습니다.';
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                '로그인',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32.0),
              CustomTextForm(
                controller: idController,
                hintText: '아이디',
              ),
              const SizedBox(height: 16.0),
              CustomTextForm(
                controller: passwordController,
                hintText: '비밀번호',
                obscureText: true,
              ),
              const SizedBox(height: 48.0),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}

