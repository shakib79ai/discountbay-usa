import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DiscountBay design tokens — mirrors the CSS custom properties on the website.
class DB {
  DB._();

  static const ink = Color(0xFF12203A);
  static const inkSoft = Color(0xFF1C3357);
  static const paper = Color(0xFFFBF7EE);
  static const paperDim = Color(0xFFF1EBDC);
  static const coral = Color(0xFFFF5A47);
  static const mustard = Color(0xFFFFC145);
  static const mint = Color(0xFF3FB88C);

  /// rgba(18, 32, 58, 0.14)
  static const line = Color(0x2412203A);

  /// rgba(251, 247, 238, 0.22)
  static const lineOnInk = Color(0x38FBF7EE);

  static const radius = 4.0;
  static const gutter = 16.0;

  // ---------- Typography ----------
  // Anton = display, Archivo = headings, Inter = body, IBM Plex Mono = codes.
  // Archivo and Inter are bundled in assets/fonts (work offline); Anton and IBM Plex Mono
  // come from google_fonts and are cached after first launch.

  static TextStyle display(double size, {Color color = paper}) => GoogleFonts.anton(
        fontSize: size,
        color: color,
        height: 1.0,
        letterSpacing: size * 0.01,
      );

  static TextStyle heading(double size, {Color color = ink, FontWeight weight = FontWeight.w800}) =>
      TextStyle(fontFamily: 'Archivo', fontSize: size, color: color, fontWeight: weight, height: 1.2);

  static TextStyle subdisplay(double size, {Color color = ink}) => TextStyle(
        fontFamily: 'Archivo',
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: size * 0.03,
      );

  static TextStyle body(double size, {Color color = ink, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: 'Inter', fontSize: size, color: color, fontWeight: weight, height: 1.45);

  static TextStyle mono(double size, {Color color = ink, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, color: color, fontWeight: weight, letterSpacing: size * 0.08);

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: coral,
        onPrimary: ink,
        secondary: mustard,
        onSecondary: ink,
        tertiary: mint,
        onTertiary: ink,
        error: coral,
        onError: ink,
        surface: ink,
        onSurface: paper,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Inter', bodyColor: paper, displayColor: paper),
      appBarTheme: AppBarTheme(
        backgroundColor: ink,
        foregroundColor: paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: heading(18, color: paper),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: mustard,
        contentTextStyle: body(14, weight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: line,
    );
  }
}
