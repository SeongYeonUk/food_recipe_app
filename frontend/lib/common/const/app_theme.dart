// lib/common/app_theme.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

import 'package:flutter/material.dart';

class AppTheme {
  // 1. 디자이너가 요청한 커스텀 색상들을 정의합니다.
  static const Color primaryColor = Color(0xFFE5A88A);    // 메인 살구색/갈색
  static const Color accentColor = Color(0xFF88AB8E);     // 포인트 연두색
  static const Color lightBackgroundColor = Color(0xFFFAF6F0); // 연한 배경색
  static final Color destructiveColor = Colors.red[700]!;     // 삭제 버튼 등

  // 2. 앱 전체 테마 Getter
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      // 3. 앱의 핵심 색상 체계를 우리가 정의한 색상으로 설정합니다.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: lightBackgroundColor,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.black87,
        onSurface: Colors.black87,
      ),

      scaffoldBackgroundColor: lightBackgroundColor,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),

      // (수정됨) 카드 테마
      // CardTheme -> CardThemeData 로 클래스 이름을 수정했습니다.
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),

      // 다이얼로그 테마
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
    );
  }
}







