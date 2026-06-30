import 'package:flutter/material.dart';

import 'app_appearance.dart';

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

  static ThemeData lightFor(AppVisualTheme visualTheme) {
    return _build(_paletteFor(visualTheme, Brightness.light), Brightness.light);
  }

  static ThemeData darkFor(AppVisualTheme visualTheme) {
    return _build(_paletteFor(visualTheme, Brightness.dark), Brightness.dark);
  }

  static AppPalette _paletteFor(
    AppVisualTheme visualTheme,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final base = dark ? AppPalette.dark : AppPalette.light;

    switch (visualTheme) {
      case AppVisualTheme.mirroric:
        return base.copyWith(
          brand: dark ? const Color(0xFFE0A36D) : const Color(0xFFC78B5F),
          success: dark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A),
        );
      case AppVisualTheme.manuscript:
        return base.copyWith(
          brand: dark ? const Color(0xFF8FB3E8) : const Color(0xFF183457),
          background: dark ? const Color(0xFF0F172A) : const Color(0xFFF7F8F3),
          card: dark ? const Color(0xFF151E2F) : const Color(0xFFFFFFFF),
        );
      case AppVisualTheme.ink:
        return base.copyWith(
          brand: dark ? const Color(0xFFE57373) : const Color(0xFFB23A3A),
          background: dark ? const Color(0xFF151313) : const Color(0xFFFBFAF7),
        );
      case AppVisualTheme.classic:
        return base.copyWith(
          brand: dark ? const Color(0xFFE5E7EB) : const Color(0xFF111111),
        );
      case AppVisualTheme.azure:
        return base.copyWith(
          brand: dark ? const Color(0xFF7FB4FF) : const Color(0xFF2F64E8),
          success: dark ? const Color(0xFF67E8F9) : const Color(0xFF0891B2),
        );
      case AppVisualTheme.jade:
        return base.copyWith(
          brand: dark ? const Color(0xFF74E3A2) : const Color(0xFF4CD779),
          success: dark ? const Color(0xFFA7F3D0) : const Color(0xFF16A34A),
        );
      case AppVisualTheme.violet:
        return base.copyWith(
          brand: dark ? const Color(0xFFC084FC) : const Color(0xFF9333EA),
          background: dark ? const Color(0xFF15111F) : const Color(0xFFFCFAFF),
        );
      case AppVisualTheme.ember:
        return base.copyWith(
          brand: dark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
          background: dark ? const Color(0xFF17120A) : const Color(0xFFFFFCF5),
        );
      case AppVisualTheme.rose:
        return base.copyWith(
          brand: dark ? const Color(0xFFF472B6) : const Color(0xFFB0477C),
          background: dark ? const Color(0xFF1A1117) : const Color(0xFFFFFAFC),
        );
      case AppVisualTheme.ivory:
        return base.copyWith(
          brand: dark ? const Color(0xFFD6C7B0) : const Color(0xFF9BA791),
          background: dark ? const Color(0xFF151610) : const Color(0xFFFBFAF3),
        );
      case AppVisualTheme.starCloud:
        return base.copyWith(
          brand: dark ? const Color(0xFF22D3EE) : const Color(0xFF078BA3),
          background: dark ? const Color(0xFF07151C) : const Color(0xFFF6FCFE),
        );
    }
  }

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.brand,
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
