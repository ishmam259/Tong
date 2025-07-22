// This is a basic Flutter widget test for the Tong messaging app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:tong/main.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('test');
  });

  testWidgets('Tong app loads onboarding screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TongApp());
    await tester.pumpAndSettle();

    // Verify that the onboarding screen loads
    expect(find.text('Welcome to Tong'), findsOneWidget);
    expect(find.text('Anonymous Identity'), findsOneWidget);
  });

  testWidgets('Can navigate through identity setup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TongApp());
    await tester.pumpAndSettle();

    // Find and tap the Anonymous Identity button
    final anonymousButton = find.text('Anonymous Identity');
    expect(anonymousButton, findsOneWidget);

    await tester.tap(anonymousButton);
    await tester.pumpAndSettle();

    // Verify we can see the nickname input field
    expect(find.byType(TextField), findsOneWidget);
  });
}
