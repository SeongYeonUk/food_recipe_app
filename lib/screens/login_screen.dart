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
  // 1. Scaffold에 붙여줄 고유한 '이름표(Key)'를 만듭니다.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    // 3. SnackBar를 보여줄 때, 이름표(Key)를 통해 Scaffold의 정확한 context를 찾아 사용합니다.
    // 이렇게 하면 절대로 오류가 발생하지 않습니다.
    final scaffoldMessenger = ScaffoldMessenger.of(_scaffoldKey.currentContext!);

    if (email.isEmpty || password.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    final success = await _userRepository.login(email, password);

    if (mounted) {
      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('로그인에 성공했습니다!')),
        );
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('이메일 또는 비밀번호가 일치하지 않습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. Scaffold 위젯에 우리가 만든 이름표(Key)를 붙여줍니다.
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 스크롤이 필요한 상단 부분을 Expanded와 SingleChildScrollView로 감쌉니다.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text('환영합니다!', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      const Text('이메일과 비밀번호를 입력해주세요.', style: TextStyle(fontSize: 16, color: BODY_TEXT_COLOR)),
                      const SizedBox(height: 48),
                      CustomTextForm(controller: _emailController, hintText: '이메일을 입력해주세요.'),
                      const SizedBox(height: 16.0),
                      CustomTextForm(controller: _passwordController, hintText: '비밀번호를 입력해주세요.', obscureText: true),
                    ],
                  ),
                ),
              ),
              // 화면 하단에 고정될 버튼
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                child: ElevatedButton(
                  onPressed: _login, // 이제 버튼은 _login 함수를 호출하기만 하면 됩니다.
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PRIMARY_COLOR,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}