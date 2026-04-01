// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:maitree/main.dart';
import 'package:maitree/services/settings_service.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    final settings = SettingsService();
    await tester.pumpWidget(MaitreeApp(settingsService: settings));
    // Let SplashScreen timers and animations complete
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
