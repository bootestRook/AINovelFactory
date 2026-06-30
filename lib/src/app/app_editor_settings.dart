import 'package:flutter/material.dart';

enum EditorEntityStyle { italic, bold, underline, highlight }

enum EditorParagraphSpacing { none, blankLine }

enum EditorAnnotationLineStyle { solid, dashed, dotted }

@immutable
class AppEditorSettings {
  const AppEditorSettings({
    this.fontFamily = 'Georgia',
    this.systemFonts = const [],
    this.customFonts = const [],
    this.fontSize = 16,
    this.letterSpacing = 0,
    this.lineHeight = 1.8,
    this.entityStyles = const {EditorEntityStyle.italic},
    this.paragraphIndent = 2,
    this.paragraphSpacing = EditorParagraphSpacing.blankLine,
    this.keepSpaces = true,
    this.annotationEnabled = false,
    this.annotationLineStyle = EditorAnnotationLineStyle.solid,
    this.annotationColor = const Color(0xFFFF6F6F),
  });

  final String fontFamily;
  final List<String> systemFonts;
  final List<String> customFonts;
  final double fontSize;
  final double letterSpacing;
  final double lineHeight;
  final Set<EditorEntityStyle> entityStyles;
  final int paragraphIndent;
  final EditorParagraphSpacing paragraphSpacing;
  final bool keepSpaces;
  final bool annotationEnabled;
  final EditorAnnotationLineStyle annotationLineStyle;
  final Color annotationColor;

  AppEditorSettings copyWith({
    String? fontFamily,
    List<String>? systemFonts,
    List<String>? customFonts,
    double? fontSize,
    double? letterSpacing,
    double? lineHeight,
    Set<EditorEntityStyle>? entityStyles,
    int? paragraphIndent,
    EditorParagraphSpacing? paragraphSpacing,
    bool? keepSpaces,
    bool? annotationEnabled,
    EditorAnnotationLineStyle? annotationLineStyle,
    Color? annotationColor,
  }) {
    return AppEditorSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      systemFonts: systemFonts ?? this.systemFonts,
      customFonts: customFonts ?? this.customFonts,
      fontSize: fontSize ?? this.fontSize,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      entityStyles: entityStyles ?? this.entityStyles,
      paragraphIndent: paragraphIndent ?? this.paragraphIndent,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      keepSpaces: keepSpaces ?? this.keepSpaces,
      annotationEnabled: annotationEnabled ?? this.annotationEnabled,
      annotationLineStyle: annotationLineStyle ?? this.annotationLineStyle,
      annotationColor: annotationColor ?? this.annotationColor,
    );
  }

  AppEditorSettings addCustomFont(String fontFamily) {
    final name = fontFamily.trim();
    if (name.isEmpty ||
        fontOptions.contains(name) ||
        customFonts.contains(name)) {
      return this;
    }
    return copyWith(
      fontFamily: name,
      customFonts: [...customFonts, name],
    );
  }

  List<String> get fontOptions {
    final seen = <String>{};
    final fonts = <String>[];

    for (final font in [
      ...defaultEditorFonts,
      ...systemFonts,
      ...customFonts,
    ]) {
      final name = font.trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) {
        continue;
      }
      fonts.add(name);
    }

    return fonts;
  }
}

const defaultEditorFonts = [
  'Microsoft YaHei UI',
  'SimSun',
  'SimHei',
  'KaiTi',
  'FangSong',
  'DengXian',
  'Arial',
  'Calibri',
  'Cambria',
  'Georgia',
  'Times New Roman',
  'Garamond',
  'Verdana',
  'Tahoma',
  'Segoe UI',
  'Consolas',
  'Courier New',
  'Noto Sans CJK SC',
  'Source Han Serif SC',
  'PingFang SC',
  'Heiti SC',
];

class AppEditorSettingsScope extends InheritedWidget {
  const AppEditorSettingsScope({
    super.key,
    required this.settings,
    required super.child,
  });

  final AppEditorSettings settings;

  static AppEditorSettings of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppEditorSettingsScope>()
            ?.settings ??
        const AppEditorSettings();
  }

  @override
  bool updateShouldNotify(AppEditorSettingsScope oldWidget) {
    return settings != oldWidget.settings;
  }
}
