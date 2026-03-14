import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';
import 'widgetbook/magickit_widgetbook_page.dart';

void main() {
  runApp(const MagicKitExampleApp());
}

class MagicKitExampleApp extends StatelessWidget {
  const MagicKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MagicKit Widget Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D4AF5)),
        extensions: [MagicTheme.light()],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B82F8),
          brightness: Brightness.dark,
        ),
        extensions: [MagicTheme.dark()],
      ),
      home: const MagicKitWidgetBookPage(),
    );
  }
}
