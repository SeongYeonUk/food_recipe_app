// lib/common/app_theme.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해서 테스트해보세요.

import 'package:flutter/material.dart';

class AppTheme {
  // 앱 전체 테마 Getter
  static ThemeData get theme {
    return ThemeData(
      // 가장 기본적인 색상 체계만 사용
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true, // 최신 머티리얼 디자인 사용

      // 앱바 테마
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),

      // 플로팅 액션 버튼 테마
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.amber,
      ),
    );
  }
}




