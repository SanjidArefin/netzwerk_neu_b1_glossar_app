import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glossary.dart';
import 'screens/glossary_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.sidebar,
      systemNavigationBarColor: AppColors.canvas,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const B1GlossarApp());
}

class B1GlossarApp extends StatefulWidget {
  const B1GlossarApp({super.key, this.loader});

  final Future<GlossaryData> Function()? loader;

  @override
  State<B1GlossarApp> createState() => _B1GlossarAppState();
}

class _B1GlossarAppState extends State<B1GlossarApp> {
  var _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'B1 Glossar',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(_darkMode ? Brightness.dark : Brightness.light),
      home: GlossaryHome(
        loader: widget.loader ?? () => GlossaryData.loadFromAsset(),
        darkMode: _darkMode,
        onThemeChanged: () => setState(() => _darkMode = !_darkMode),
      ),
    );
  }
}
