import 'package:flutter/material.dart';

const kGreen = Color(0xFF00A251);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kGreen,
    primary: kGreen,
    onPrimary: Colors.black,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
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