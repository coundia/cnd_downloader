import 'package:flutter/material.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/settings_page.dart';

class FastDownApp extends StatelessWidget {
  const FastDownApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastDown',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      routes: {
        '/': (_) => const HomePage(),
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
}
