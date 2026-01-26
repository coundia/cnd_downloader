// lib/app.dart
import 'package:flutter/material.dart';
import 'ui/pages/shell_page.dart';
import 'ui/pages/download_page.dart';
import 'ui/pages/settings_page.dart';

class FastDownApp extends StatelessWidget {
  const FastDownApp({super.key});

  static const appName = 'CND IPTV'; // change here

  ThemeData _lightTheme() {
    final cs = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  ThemeData _darkTheme() {
    final cs = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.35),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainer.withOpacity(0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: ThemeMode.system,
      routes: {
        '/': (_) => const ShellPage(),
        '/downloads': (_) => const HomePage(),
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
}
