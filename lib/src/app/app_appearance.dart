import 'package:flutter/material.dart';

enum AppThemePreference { light, dark, system }

enum AppVisualTheme {
  mirroric,
  manuscript,
  ink,
  classic,
  azure,
  jade,
  violet,
  ember,
  rose,
  ivory,
  starCloud,
}

enum AppBackgroundKind { none, solid, builtIn, custom }

enum AppSolidBackground {
  mirroric,
  manuscript,
  ink,
  classic,
  azure,
  jade,
  violet,
  ember,
  rose,
  ivory,
  starCloud,
}

enum AppBuiltInBackground {
  vellum,
  distantMountain,
  starrySky,
  northernMist,
  bareTree,
  plumShadow,
  loneBoat,
}

enum AppBackgroundFit { cover, contain, fill, tile }

extension AppSolidBackgroundStyle on AppSolidBackground {
  Color get color {
    switch (this) {
      case AppSolidBackground.mirroric:
        return const Color(0xFFF8F3EE);
      case AppSolidBackground.manuscript:
        return const Color(0xFFF6F7F1);
      case AppSolidBackground.ink:
        return const Color(0xFFFBFAF7);
      case AppSolidBackground.classic:
        return const Color(0xFFF7F7F7);
      case AppSolidBackground.azure:
        return const Color(0xFFF5F8FF);
      case AppSolidBackground.jade:
        return const Color(0xFFF5FFF8);
      case AppSolidBackground.violet:
        return const Color(0xFFFCFAFF);
      case AppSolidBackground.ember:
        return const Color(0xFFFFFBF2);
      case AppSolidBackground.rose:
        return const Color(0xFFFFFAFC);
      case AppSolidBackground.ivory:
        return const Color(0xFFFBFAF3);
      case AppSolidBackground.starCloud:
        return const Color(0xFFF6FCFE);
    }
  }
}

extension AppBuiltInBackgroundStyle on AppBuiltInBackground {
  LinearGradient get gradient {
    switch (this) {
      case AppBuiltInBackground.vellum:
        return const LinearGradient(
          colors: [Color(0xFFFFF9EF), Color(0xFFF3E4D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppBuiltInBackground.distantMountain:
        return const LinearGradient(
          colors: [Color(0xFFEAF3FA), Color(0xFFC7D6E7), Color(0xFFF9FBFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        );
      case AppBuiltInBackground.starrySky:
        return const LinearGradient(
          colors: [Color(0xFF0C1445), Color(0xFF182A76), Color(0xFF060914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppBuiltInBackground.northernMist:
        return const LinearGradient(
          colors: [Color(0xFFF5F2EA), Color(0xFFC8D0CF), Color(0xFF6F8587)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppBuiltInBackground.bareTree:
        return const LinearGradient(
          colors: [Color(0xFFF7F0E5), Color(0xFFE6DDCD), Color(0xFFCCC0AD)],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        );
      case AppBuiltInBackground.plumShadow:
        return const LinearGradient(
          colors: [Color(0xFFEDE8DF), Color(0xFFD5D0C5), Color(0xFFB5A696)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppBuiltInBackground.loneBoat:
        return const LinearGradient(
          colors: [Color(0xFFFAF3DF), Color(0xFFE2D5B6), Color(0xFFB9B29D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

extension AppBackgroundFitStyle on AppBackgroundFit {
  BoxFit get boxFit {
    switch (this) {
      case AppBackgroundFit.cover:
        return BoxFit.cover;
      case AppBackgroundFit.contain:
        return BoxFit.contain;
      case AppBackgroundFit.fill:
        return BoxFit.fill;
      case AppBackgroundFit.tile:
        return BoxFit.none;
    }
  }
}

@immutable
class AppAppearance {
  const AppAppearance({
    this.themePreference = AppThemePreference.light,
    this.visualTheme = AppVisualTheme.mirroric,
    this.backgroundKind = AppBackgroundKind.none,
    this.solidBackground = AppSolidBackground.mirroric,
    this.builtInBackground = AppBuiltInBackground.vellum,
    this.backgroundFit = AppBackgroundFit.cover,
    this.customBackgroundPath,
  });

  final AppThemePreference themePreference;
  final AppVisualTheme visualTheme;
  final AppBackgroundKind backgroundKind;
  final AppSolidBackground solidBackground;
  final AppBuiltInBackground builtInBackground;
  final AppBackgroundFit backgroundFit;
  final String? customBackgroundPath;

  ThemeMode get themeMode {
    switch (themePreference) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  AppAppearance copyWith({
    AppThemePreference? themePreference,
    AppVisualTheme? visualTheme,
    AppBackgroundKind? backgroundKind,
    AppSolidBackground? solidBackground,
    AppBuiltInBackground? builtInBackground,
    AppBackgroundFit? backgroundFit,
    String? customBackgroundPath,
    bool clearCustomBackgroundPath = false,
  }) {
    return AppAppearance(
      themePreference: themePreference ?? this.themePreference,
      visualTheme: visualTheme ?? this.visualTheme,
      backgroundKind: backgroundKind ?? this.backgroundKind,
      solidBackground: solidBackground ?? this.solidBackground,
      builtInBackground: builtInBackground ?? this.builtInBackground,
      backgroundFit: backgroundFit ?? this.backgroundFit,
      customBackgroundPath: clearCustomBackgroundPath
          ? null
          : customBackgroundPath ?? this.customBackgroundPath,
    );
  }
}

class AppAppearanceScope extends InheritedWidget {
  const AppAppearanceScope({
    super.key,
    required this.appearance,
    required super.child,
  });

  final AppAppearance appearance;

  static AppAppearance of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppAppearanceScope>()
            ?.appearance ??
        const AppAppearance();
  }

  @override
  bool updateShouldNotify(AppAppearanceScope oldWidget) {
    return appearance != oldWidget.appearance;
  }
}
