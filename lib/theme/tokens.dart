import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DiscountBay design tokens — the 2026 store-front design (light pages, photo cards,
/// each store in its own brand colour). Same values as the web redesign.
class DB {
  DB._();

  // ---------- Store-front palette ----------
  static const ink = Color(0xFF12203A); // text, dark bands, default buttons
  static const inkSoft = Color(0xFF1B2E52);
  static const bg = Color(0xFFF4F6F9); // page background
  static const card = Colors.white;
  static const border = Color(0xFFE1E7EF);
  static const borderStrong = Color(0xFFCFDAE7);
  static const muted = Color(0xFF5B6478);
  static const body2 = Color(0xFF4A5468);
  static const orange = Color(0xFFE25F12); // DiscountBay accent
  static const orangeSoft = Color(0xFFFFF1E6);
  static const sale = Color(0xFFE2453C); // "UP TO 70% OFF" badges
  static const price = Color(0xFFB42318); // discount / price text
  static const verified = Color(0xFF1F7A57);
  static const logoTop = Color(0xFFFF9A3D);
  static const logoBottom = Color(0xFFE2560C);

  // ---------- Kept for older widgets ----------
  static const paper = Color(0xFFFBF7EE);
  static const paperDim = Color(0xFFF1EBDC);
  static const coral = Color(0xFFFF5A47);
  static const mustard = Color(0xFFFFC145);
  static const mint = Color(0xFF3FB88C);
  static const line = Color(0x2412203A);
  static const lineOnInk = Color(0x38FBF7EE);

  static const radius = 4.0;
  static const cardRadius = 18.0;
  static const gutter = 16.0;

  static const cardShadow = [BoxShadow(color: Color(0x14122039), blurRadius: 20, offset: Offset(0, 8))];

  // ---------- Typography ----------
  // Archivo Black = big headlines, Archivo = headings, Inter = body.
  // Archivo and Inter are bundled in assets/fonts; Archivo Black comes from google_fonts.

  /// Big headline ("Save up to 90%", page titles).
  static TextStyle headline(double size, {Color color = ink}) =>
      GoogleFonts.archivoBlack(fontSize: size, color: color, height: 1.02);

  static TextStyle display(double size, {Color color = paper}) =>
      GoogleFonts.anton(fontSize: size, color: color, height: 1.0, letterSpacing: size * 0.01);

  static TextStyle heading(double size, {Color color = ink, FontWeight weight = FontWeight.w800}) =>
      TextStyle(fontFamily: 'Archivo', fontSize: size, color: color, fontWeight: weight, height: 1.25);

  static TextStyle subdisplay(double size, {Color color = ink}) => TextStyle(
        fontFamily: 'Archivo',
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: size * 0.03,
      );

  static TextStyle body(double size, {Color color = ink, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: 'Inter', fontSize: size, color: color, fontWeight: weight, height: 1.45);

  /// Small uppercase label ("ELECTRONICS", "CATEGORY").
  static TextStyle label(double size, {Color color = muted}) => TextStyle(
      fontFamily: 'Inter', fontSize: size, color: color, fontWeight: FontWeight.w700, letterSpacing: size * 0.09);

  static TextStyle mono(double size, {Color color = ink, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, color: color, fontWeight: weight, letterSpacing: size * 0.12);

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ink,
        onPrimary: Colors.white,
        secondary: orange,
        onSecondary: Colors.white,
        tertiary: verified,
        onTertiary: Colors.white,
        error: sale,
        onError: Colors.white,
        surface: bg,
        onSurface: ink,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Inter', bodyColor: ink, displayColor: ink),
      appBarTheme: AppBarTheme(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: headline(20, color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: body(14, color: Colors.white, weight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: orange),
      dividerColor: border,
    );
  }
}
