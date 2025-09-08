import 'package:flutter/material.dart';

ThemeData light = ThemeData(
  // fontFamily: AppConstants.fontFamily,
  primaryColor: const Color.fromARGB(255, 13, 179, 116),
  secondaryHeaderColor: const Color(0xFF000743),
  disabledColor: const Color(0xFFA0A4A8),
  brightness: Brightness.light,
  hintColor: const Color(0xFF9A9A9A),
  cardColor: Colors.white,
  shadowColor: Colors.black.withValues(alpha: 0.03),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B3B3B))),
  colorScheme: const ColorScheme.light(primary: Color.fromARGB(255, 13, 179, 116),
   secondary: Color.fromARGB(255, 13, 179, 116), surface: Color(0xFFF6FBFF)).copyWith(error: const Color(0xFFE84D4F)),
  popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.white),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
  bottomAppBarTheme: const BottomAppBarThemeData(
    color: Colors.white, height: 60, padding: EdgeInsets.symmetric(vertical: 5),
  ),
  // floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
  // bottomAppBarTheme: const BottomAppBarTheme(color: Colors.white, height: 60, padding: EdgeInsets.symmetric(vertical: 5)),
  dividerTheme: const DividerThemeData(thickness: 0.2, color: Color(0xFFA0A4A8)),
  tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
);