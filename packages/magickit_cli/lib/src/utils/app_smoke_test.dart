import 'dart:io';

/// Replaces Flutter's counter `test/widget_test.dart` after `main.dart` is
/// rewritten by `init` or `kickstart`.
void writeAppSmokeTest({
  required String appName,
  required String appClassName,
  bool expectKickstartFlow = false,
}) {
  final file = File('test/widget_test.dart');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    expectKickstartFlow
        ? _kickstartSmokeTest(appName, appClassName)
        : _initSmokeTest(appName, appClassName),
  );
}

String _initSmokeTest(String appName, String appClassName) => '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:$appName/core/dependency_injection/injector.dart';
import 'package:$appName/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MagicKit app builds after dependencies are configured',
      (tester) async {
    await configureDependencies();
    await tester.pumpWidget(const $appClassName());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
''';

String _kickstartSmokeTest(String appName, String appClassName) => '''
import 'package:flutter_test/flutter_test.dart';
import 'package:$appName/core/dependency_injection/injector.dart';
import 'package:$appName/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MagicKit app builds after dependencies are configured',
      (tester) async {
    await configureDependencies();
    await tester.pumpWidget(const $appClassName());
    await tester.pump();
    _ignoreMissingAssets(tester);
    expect(find.text('MagicKit'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    _ignoreMissingAssets(tester);
    expect(find.text('Welcome'), findsOneWidget);
  });
}

void _ignoreMissingAssets(WidgetTester tester) {
  Object? error;
  while ((error = tester.takeException()) != null) {
    final message = error.toString();
    final missingAsset = message.contains('Unable to load asset') ||
        message.contains('HTTP request failed');
    if (!missingAsset) {
      fail(message);
    }
  }
}
''';
