import 'package:flutter/material.dart';
import 'package:food_recipe_app/common/component/custom_text_form.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final UserRepository _userRepository = UserRepository();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final scaffoldMessenger =
    ScaffoldMessenger.of(_scaffoldKey.currentContext!);

    final uid = _idController.text;
    final password = _passwordController.text;

    // 1. 빈칸 확인
    if (uid.isEmpty || password.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    // 2. UserRepository를 통해 서버에 로그인 요청
    final String? token = await _userRepository.login(uid, password);

    // 3. 결과에 따른 UI 처리 (mounted 확인 필수)
    if (mounted) {
      if (token != null) {
        // 로그인 성공 시
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('로그인에 성공했습니다!')),
        );

        // TODO: 받은 토큰을 flutter_secure_storage 등을 이용해 안전하게 저장해야 합니다.
        print('발급된 토큰: $token');

        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        // 로그인 실패 시
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('아이디 또는 비밀번호가 일치하지 않습니다.')),
        );
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
              const Text('로그인',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32.0),
              CustomTextForm(
                  controller: _idController, hintText: '아이디'),
              const SizedBox(height: 16.0),
              CustomTextForm(
                  controller: _passwordController,
                  hintText: '비밀번호',
                  obscureText: true),
              const SizedBox(height: 48.0),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Login',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
