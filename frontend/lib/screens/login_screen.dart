// frontend/lib/screens/login_screen.dart

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

  // [수정] 변수명을 idController로 통일 (또는 uidController)
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final UserRepository userRepository = UserRepository();

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final scaffoldMessenger =
    ScaffoldMessenger.of(_scaffoldKey.currentContext!);

    final uid = idController.text;
    final password = passwordController.text;

    if (uid.isEmpty || password.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    final String? token = await userRepository.login(uid, password);

    if (mounted) {
      if (token != null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('로그인에 성공했습니다!')),
        );


        Navigator.of(context).pushReplacementNamed('/main');
      } else {
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
                  controller: idController, hintText: '아이디'),
              const SizedBox(height: 16.0),
              CustomTextForm(
                  controller: passwordController,
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
