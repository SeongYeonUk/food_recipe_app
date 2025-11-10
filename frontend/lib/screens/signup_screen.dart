import 'dart:convert';
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

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
  TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  final UserRepository _userRepository = UserRepository();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _signUp() async {
    final scaffoldMessenger =
    ScaffoldMessenger.of(_scaffoldKey.currentContext!);

    final uid = _idController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();
    final nickname = _nicknameController.text.trim();

    final passwordValidationRegExp = RegExp(r'^[a-zA-Z0-9]+$');
    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);

    if (uid.isEmpty ||
        password.isEmpty ||
        passwordConfirm.isEmpty ||
        nickname.isEmpty) {
      scaffoldMessenger
          .showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요.')));
      return;
    }
    if (uid.length > 12) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('아이디는 12글자 이내로 설정해주세요.')));
      return;
    }
    if (nickname.length > 8) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('닉네임은 8글자 이내로 설정해주세요.')));
      return;
    }
    if (password.length > 12) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('비밀번호는 12글자 이내로 설정해주세요.')));
      return;
    }
    if (!passwordValidationRegExp.hasMatch(password)) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('비밀번호에는 특수문자를 사용할 수 없습니다.')));
      return;
    }
    if (!hasLetters || !hasNumbers) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('비밀번호는 영어와 숫자를 모두 포함해야 합니다.')));
      return;
    }
    if (password != passwordConfirm) {
      scaffoldMessenger
          .showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return;
    }

    try {
      final response = await _userRepository.signUp(uid, password, nickname, passwordConfirm);

      if (response.statusCode == 201) {
        showSuccessDialog();
      } else if (response.statusCode == 409) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('닉네임 또는 아이디가 같습니다.')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('알 수 없는 오류가 발생했습니다.')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('서버에 연결할 수 없습니다: $e')),
      );
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
                Navigator.pushReplacementNamed(context, '/login');
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
        automaticallyImplyLeading: false,
        title: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text('회원가입 하세요!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32.0),
              CustomTextForm(
                  controller: _idController, hintText: '아이디 (12자 이내)'),
              const SizedBox(height: 16.0),
              CustomTextForm(
                  controller: _passwordController,
                  hintText: '비밀번호 (12자 이내, 특수문자 불가)',
                  obscureText: true),
              const SizedBox(height: 16.0),
              CustomTextForm(
                  controller: _passwordConfirmController,
                  hintText: '비밀번호 확인',
                  obscureText: true),
              const SizedBox(height: 16.0),
              CustomTextForm(
                  controller: _nicknameController, hintText: '닉네임 (8자 이내)'),
              const SizedBox(height: 48.0),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Continue',
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

