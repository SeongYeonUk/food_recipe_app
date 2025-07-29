import 'package:flutter/material.dart';
import 'package:food_recipe_app/common/Component/custom_text_form.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/user_repository.dart';

// StatefulWidget으로 변경하여 컨트롤러와 같은 상태를 관리
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 텍스트 필드의 값을 가져오기 위한 컨트롤러
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  // UserRepository 인스턴스 가져오기
  final UserRepository _userRepository = UserRepository();

  // 위젯이 제거될 때 컨트롤러 리소스를 해제하기 위해 dispose 메서드 사용
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // 회원가입 로직을 처리하는 함수
  void _signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    // 1. 유효성 검사
    if (email.isEmpty || password.isEmpty || passwordConfirm.isEmpty) {
      _showSnackBar('모든 필드를 입력해주세요.');
      return;
    }
    if (password != passwordConfirm) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    // 2. UserRepository를 통해 회원가입 시도
    final success = await _userRepository.signUp(email, password);

    // 3. 결과에 따른 처리
    if (mounted) { // 비동기 작업 후 위젯이 여전히 화면에 있는지 확인
      if (success) {
        _showSnackBar('회원가입에 성공했습니다!');
        Navigator.of(context).pop(); // 성공 시 이전 화면(로그인)으로 돌아가기
      } else {
        _showSnackBar('이미 존재하는 이메일입니다.');
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  '회원가입',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                const Text(
                  '새로운 계정을 생성합니다.',
                  style: TextStyle(fontSize: 16, color: BODY_TEXT_COLOR),
                ),
                const SizedBox(height: 48),
                CustomTextForm(
                  controller: _emailController, // 이메일 컨트롤러 연결
                  hintText: '이메일을 입력해주세요.',
                ),
                const SizedBox(height: 16),
                CustomTextForm(
                  controller: _passwordController, // 비밀번호 컨트롤러 연결
                  hintText: '비밀번호를 입력해주세요.',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                CustomTextForm(
                  controller: _passwordConfirmController, // 비밀번호 확인 컨트롤러 연결
                  hintText: '비밀번호를 다시 입력해주세요.',
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _signUp, // '가입하기' 버튼에 _signUp 함수 연결
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: PRIMARY_COLOR,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '가입하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
