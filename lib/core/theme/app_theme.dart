import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _green = Color(0xFF173F30);
  static const _cream = Color(0xFFFFF8EA);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _green,
      primary: _green,
      surface: _cream,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: _green, fontWeight: FontWeight.w800),
    ),
  );
}
