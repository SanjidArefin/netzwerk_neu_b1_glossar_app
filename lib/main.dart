import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glossary.dart';
import 'screens/glossary_screen.dart';
import 'services/glossary_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.sidebar,
      systemNavigationBarColor: AppColors.canvas,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final storedTheme = prefs.getString('b1_glossar_theme') ?? 'dark';
  runApp(B1GlossarApp(initialDarkMode: storedTheme == 'dark'));
}

class B1GlossarApp extends StatefulWidget {
  const B1GlossarApp({super.key, this.loader, this.initialDarkMode = true});

  final Future<GlossaryData> Function()? loader;
  final bool initialDarkMode;

  @override
  State<B1GlossarApp> createState() => _B1GlossarAppState();
}

class _B1GlossarAppState extends State<B1GlossarApp> {
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.initialDarkMode;
  }

  Future<void> _toggleTheme() async {
    setState(() => _darkMode = !_darkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('b1_glossar_theme', _darkMode ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'B1 Glossary',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(_darkMode ? Brightness.dark : Brightness.light),
      home: GlossaryHome(
        loader: widget.loader ?? () => GlossaryService().load(),
        darkMode: _darkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}
