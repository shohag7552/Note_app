import 'package:flutter/material.dart';

ThemeData light = ThemeData(
  // fontFamily: AppConstants.fontFamily,
  primaryColor: const Color(0xFF2A9849),
  secondaryHeaderColor: const Color(0xFF000743),
  disabledColor: const Color(0xFFA0A4A8),
  brightness: Brightness.light,
  hintColor: const Color(0xFF9A9A9A),
  cardColor: Colors.white,
  shadowColor: Colors.black.withOpacity(0.03),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B3B3B))),
  colorScheme: const ColorScheme.light(primary: Color(0xFF2A9849), secondary: Color(0xFF2A9849), surface: Color(0xFFF6FBFF)).copyWith(error: const Color(0xFFE84D4F)),
  popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.white),
  dialogTheme: const DialogTheme(surfaceTintColor: Colors.white),
  // floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
  // bottomAppBarTheme: const BottomAppBarTheme(color: Colors.white, height: 60, padding: EdgeInsets.symmetric(vertical: 5)),
  dividerTheme: const DividerThemeData(thickness: 0.2, color: Color(0xFFA0A4A8)),
  tabBarTheme: const TabBarTheme(dividerColor: Colors.transparent),
);