import 'package:flutter/material.dart';

const kGreen = Color(0xFF00A251);
const kNavy = Color(0xFF0B1E5B);
const kSky = Color(0xFF0090D8);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kGreen,
    primary: kGreen,
    onPrimary: Colors.black,
    secondary: kNavy,
    tertiary: kSky,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kNavy,
    foregroundColor: Colors.white,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kGreen,
      foregroundColor: Colors.black,
      minimumSize: const Size.fromHeight(48),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);