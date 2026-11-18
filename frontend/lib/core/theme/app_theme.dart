import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colores de la marca SafeBite, tomados del logo: verde profundo del escudo
/// y de "Safe", verde lima de "Bite". El ámbar se mantiene para avisos
/// ("Dudoso") y el rojo para lo peligroso ("No apto").
class AppColors {
  /// Verde de botones, íconos y textos destacados.
  static const Color primary = Color(0xFF14763F);

  /// Verde profundo del logo: encabezados y barra de navegación.
  static const Color primaryDark = Color(0xFF0B4D2C);

  /// Verde todavía más oscuro, para el final de los degradados.
  static const Color primaryDeeper = Color(0xFF05321C);

  /// Verde lima de "Bite": detalles sobre fondos oscuros.
  static const Color lime = Color(0xFF6CC51D);

  /// Verde muy claro para fondos de íconos, chips y estados "Apto".
  static const Color primarySoft = Color(0xFFE2F2E7);

  static const Color accent = Color(0xFFF5A623);
  static const Color accentSoft = Color(0xFFFFF1DC);
  static const Color danger = Color(0xFFD93A33);
  static const Color background = Color(0xFFF1F6F2);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF10251A);
  static const Color textSecondary = Color(0xFF4F6357);
  static const Color border = Color(0xFFDCE6DF);

  /// Degradado del encabezado (igual al ícono de la app).
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E5C34), primaryDark],
  );

  /// Sombra suave de las tarjetas.
  static List<BoxShadow> get sombraSuave => [
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}

class AppTheme {
  static const String fuente = 'PlusJakartaSans';

  static ThemeData light() {
    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.card,
    );

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: fuente,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: fuente,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primaryDark,
        indicatorColor: AppColors.lime,
        surfaceTintColor: Colors.transparent,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected) ? AppColors.primaryDeeper : const Color(0xFFB7CDBF),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontFamily: fuente,
            fontSize: 11,
            fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: estados.contains(WidgetState.selected) ? Colors.white : const Color(0xFFB7CDBF),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      dividerColor: AppColors.border,
    );
  }
}
