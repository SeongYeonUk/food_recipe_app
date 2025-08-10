import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_recipe_app/common/const/colors.dart';
import 'package:food_recipe_app/user/auth_status.dart';
import 'package:food_recipe_app/user/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  final AuthStatus authStatus = AuthStatus();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    final authStatus = AuthStatus();
    final userModel = UserModel();

    await Future.delayed(const Duration(seconds: 2));

    final allData = await storage.readAll();
    final token = allData['ACCESS_TOKEN'];
    final userInfoString = allData['USER_INFO'];

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {

      if (token != null && userInfoString != null) {
        authStatus.setToken(token);
        userModel.loadFromMap(jsonDecode(userInfoString));
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        Navigator.of(context).pushReplacementNamed('/start');
      }
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
