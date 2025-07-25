// This is a basic Flutter widget test for the Tong messaging app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tong/main.dart';

void main() {
  testWidgets('Tong app loads welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(TongApp());
    await tester.pumpAndSettle();

    // Verify that the welcome screen loads
    expect(find.text('Welcome to Tong'), findsOneWidget);
    expect(find.text('Tong Messenger'), findsWidgets);
    expect(find.text('Advanced Multi-Network Messaging'), findsOneWidget);
    expect(find.text('Start Messaging'), findsOneWidget);
  });

  testWidgets('Can navigate to messaging screen', (WidgetTester tester) async {
    await tester.pumpWidget(TongApp());
    await tester.pumpAndSettle();

    // Find and tap the "Start Messaging" button
    final startButton = find.text('Start Messaging');
    expect(startButton, findsOneWidget);

    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // Verify we navigated to the messaging screen
    expect(find.text('Tong Messenger'), findsWidgets);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Type a message...'), findsOneWidget);
  });

  testWidgets('Can access settings screen', (WidgetTester tester) async {
    await tester.pumpWidget(TongApp());
    await tester.pumpAndSettle();

    // Navigate to messaging screen first
    await tester.tap(find.text('Start Messaging'));
    await tester.pumpAndSettle();

    // Find and tap the settings button
    final settingsButton = find.byIcon(Icons.settings);
    expect(settingsButton, findsOneWidget);

    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Verify we're in the settings screen
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('Settings screen has all sections', (WidgetTester tester) async {
    await tester.pumpWidget(TongApp());
    await tester.pumpAndSettle();

    // Navigate to messaging screen
    await tester.tap(find.text('Start Messaging'));
    await tester.pumpAndSettle();

    // Navigate to settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify all settings sections exist
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Nickname'), findsOneWidget);
  });

  testWidgets('Connection status is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(TongApp());
    await tester.pumpAndSettle();

    // Navigate to messaging screen
    await tester.tap(find.text('Start Messaging'));
    await tester.pumpAndSettle();

    // Verify connection status is shown
    expect(find.textContaining('Connected'), findsOneWidget);
  });
}
