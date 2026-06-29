import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.line,
    required this.text,
    required this.muted,
    required this.brand,
    required this.success,
    required this.heroOverlay,
    required this.shadow,
  });

  final Color background;
  final Color card;
  final Color line;
  final Color text;
  final Color muted;
  final Color brand;
  final Color success;
  final Color heroOverlay;
  final Color shadow;

  static const light = AppPalette(
    background: Color(0xFFFAFAFA),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE5E7EB),
    text: Color(0xFF111827),
    muted: Color(0xFF6B7280),
    brand: Color(0xFFD02020),
    success: Color(0xFF22C55E),
    heroOverlay: Color(0xB8FFFFFF),
    shadow: Color(0x08000000),
  );

  static const dark = AppPalette(
    background: Color(0xFF0F1115),
    card: Color(0xFF171A21),
    line: Color(0xFF2A2F3A),
    text: Color(0xFFF5F7FB),
    muted: Color(0xFF9AA3B2),
    brand: Color(0xFFFF5A5A),
    success: Color(0xFF4ADE80),
    heroOverlay: Color(0xCC171A21),
    shadow: Color(0x33000000),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? light;
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? line,
    Color? text,
    Color? muted,
    Color? brand,
    Color? success,
    Color? heroOverlay,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      brand: brand ?? this.brand,
      success: success ?? this.success,
      heroOverlay: heroOverlay ?? this.heroOverlay,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      success: Color.lerp(success, other.success, t)!,
      heroOverlay: Color.lerp(heroOverlay, other.heroOverlay, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.light.brand,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: palette.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(color: palette.muted),
        floatingLabelStyle: TextStyle(color: palette.brand),
        hintStyle: TextStyle(color: palette.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.brand),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      scaffoldBackgroundColor: palette.background,
      useMaterial3: true,
      fontFamily: 'Microsoft YaHei UI',
      extensions: [palette],
    );
  }
}
