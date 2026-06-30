import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<List<String>> loadSystemFontFamilies() async {
  if (!Platform.isWindows) {
    return const [];
  }

  const script = r'''
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.Drawing
$collection = [System.Drawing.Text.InstalledFontCollection]::new()
$collection.Families | ForEach-Object Name | Sort-Object -Unique
''';

  try {
    final result = await Process.run(
      'powershell.exe',
      const ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    ).timeout(const Duration(seconds: 3));

    if (result.exitCode != 0 || result.stdout is! String) {
      return const [];
    }

    return const LineSplitter()
        .convert(result.stdout as String)
        .map((font) => font.trim())
        .where((font) => font.isNotEmpty)
        .toSet()
        .toList();
  } on Object {
    return const [];
  }
}
