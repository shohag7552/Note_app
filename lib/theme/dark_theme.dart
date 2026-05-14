import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _accent = Color(0xFFF5F5F5);
const Color _surface = Color(0xFF0E0E0E);
const Color _card = Color(0xFF1A1A1A);
const Color _onSurface = Color(0xFFEDEDED);
const Color _muted = Color(0xFF8A8A8A);
const Color _divider = Color(0xFF2A2A2A);

ThemeData buildDarkTheme(String fontFamily) {
  final font = GoogleFonts.getFont(fontFamily);
  final ff = font.fontFamily!;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _surface,
    primaryColor: _accent,
    cardColor: _card,
    hintColor: _muted,
    disabledColor: _muted,
    shadowColor: Colors.black.withValues(alpha: 0.4),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      fontFamily: ff,
      bodyColor: _onSurface,
      displayColor: _onSurface,
    ),
    colorScheme: const ColorScheme.dark(
      primary: _accent,
      onPrimary: Color(0xFF0E0E0E),
      secondary: _accent,
      surface: _surface,
      onSurface: _onSurface,
      surfaceContainerHighest: _card,
      outline: _divider,
      error: Color(0xFFDD3135),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _surface,
      foregroundColor: _onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.getFont(
        fontFamily,
        color: _onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: const IconThemeData(color: _onSurface),
    ),
    cardTheme: CardThemeData(
      color: _card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _divider, width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _accent,
      foregroundColor: Color(0xFF0E0E0E),
      elevation: 2,
      highlightElevation: 4,
      shape: StadiumBorder(),
    ),
    dividerTheme: const DividerThemeData(thickness: 1, color: _divider, space: 1),
    popupMenuTheme: PopupMenuThemeData(
      color: _card,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _divider),
      ),
      textStyle: GoogleFonts.getFont(fontFamily, color: _onSurface, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _card,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _card,
      hintStyle: GoogleFonts.getFont(fontFamily, color: _muted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _onSurface,
      textColor: _onSurface,
    ),
    tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
  );
}
