import 'package:flutter/material.dart';
import 'package:food_recipe_app/common/component/custom_text_form.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/user_repository.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  final UserRepository _userRepository = UserRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _signUp() async {
    final scaffoldMessenger = ScaffoldMessenger.of(_scaffoldKey.currentContext!);

    final email = _emailController.text;
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;
    final nickname = _nicknameController.text;


    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);

    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    if (email.isEmpty || password.isEmpty || passwordConfirm.isEmpty || nickname.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('모두 입력해주세요.')));
      return;
    }

    if (!emailRegExp.hasMatch(email)) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('올바른 이메일 형식이 아닙니다.')));
      return;
    }
    if (nickname.length > 8) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('닉네임은 8글자 이내로 설정해주세요.')));
      return;
    }
    if (password.length < 12) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('비밀번호는 12글자 이상으로 설정해주세요.')));
      return;
    }
    if (!hasLetters || !hasNumbers) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('비밀번호는 영어와 숫자를 모두 포함해야 합니다.')));
      return;
    }
    if (password != passwordConfirm) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return;
    }

    final success = await _userRepository.signUp(email, password, nickname);

    if (mounted) {
      if (success) {
        showSuccessDialog();
      } else {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('이미 존재하는 이메일입니다.')));
      }
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('회원가입 성공'),
          content: const Text('성공적으로 회원가입 되었습니다.\n로그인 화면으로 이동합니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text('회원가입 하세요!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32.0),
                      CustomTextForm(controller: _emailController, hintText: '이메일 (로그인 시 사용)'),
                      const SizedBox(height: 16.0),
                      CustomTextForm(controller: _passwordController, hintText: '비밀번호 (12자 이상)', obscureText: true),
                      const SizedBox(height: 16.0),
                      CustomTextForm(controller: _passwordConfirmController, hintText: '비밀번호 확인', obscureText: true),
                      const SizedBox(height: 16.0),
                      CustomTextForm(controller: _nicknameController, hintText: '닉네임 (8자 이내)'),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PRIMARY_COLOR,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
