import 'package:flutter/material.dart';
import 'package:food_recipe_app/common/Component/custom_text_form.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/user_repository.dart';

// StatefulWidget으로 변경하여 사용자의 입력 상태를 관리합니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final UserRepository _userRepository = UserRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    // 간단한 유효성 검사
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('이메일과 비밀번호를 모두 입력해주세요.');
      return;
    }


    final success = await _userRepository.login(email, password);

    // 비동기 작업 후 위젯이 화면에 그대로 있는지 확인 (필수)
    if (mounted) {
      if (success) {
        // 로그인 성공 시
        _showSnackBar('로그인에 성공했습니다!');
        // MainScreen으로 이동합니다.
        // pushReplacementNamed를 사용하면 로그인 화면으로 다시 돌아올 수 없게 만듭니다.
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        // 로그인 실패 시
        _showSnackBar('이메일 또는 비밀번호가 일치하지 않습니다.');
      }
    }
  }

  // 사용자에게 메시지를 보여주기 위한 SnackBar 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // 키보드가 올라올 때 화면이 깨지지 않도록
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  '환영합니다!',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '이메일과 비밀번호를 입력해주세요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: BODY_TEXT_COLOR,
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Image.asset(
                    'asset/img/login_logo.png',
                    width: 400,
                    height: 340,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 48),
                // 5. CustomTextForm에 컨트롤러 연결
                CustomTextForm(
                  controller: _emailController,
                  hintText: '이메일을 입력해주세요.',
                ),
                const SizedBox(height: 16),
                CustomTextForm(
                  controller: _passwordController,
                  hintText: '비밀번호를 입력해주세요.',
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                // 6. 로그인 버튼에 _login 함수 연결
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: PRIMARY_COLOR,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/signup');
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 16,
                      color: PRIMARY_COLOR,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
