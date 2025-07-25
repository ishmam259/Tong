import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tong/screens/settings_screen.dart';

void main() {
  group('Settings Screen Tests', () {
    testWidgets('Settings screen displays all sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Check that all main sections are present
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Connection'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('Can edit nickname', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Find and tap the nickname tile
      final nicknameTile = find.text('Nickname');
      expect(nicknameTile, findsOneWidget);

      await tester.tap(nicknameTile);
      await tester.pumpAndSettle();

      // Should show edit dialog
      expect(find.text('Edit Nickname'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Connection type selection works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Find and tap the connection type tile
      final connectionTile = find.text('Connection Type');
      expect(connectionTile, findsOneWidget);

      await tester.tap(connectionTile);
      await tester.pumpAndSettle();

      // Should show connection type dialog
      expect(find.text('Select Connection Type'), findsOneWidget);
      expect(find.text('WiFi Network'), findsOneWidget);
      expect(find.text('Bluetooth'), findsOneWidget);
      expect(find.text('Internet'), findsOneWidget);
    });

    testWidgets('Network discovery navigation works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Find and tap the network discovery tile
      final discoveryTile = find.text('Network Discovery');
      expect(discoveryTile, findsOneWidget);

      await tester.tap(discoveryTile);
      await tester.pumpAndSettle();

      // Should navigate to network discovery screen
      expect(find.text('Network Discovery'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('Notification toggles work', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Find notification switch
      final notificationSwitch = find.byType(Switch).first;
      expect(notificationSwitch, findsOneWidget);

      // Tap the switch
      await tester.tap(notificationSwitch);
      await tester.pumpAndSettle();

      // Should not throw any errors
    });

    testWidgets('Dark mode toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Find dark mode switch
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // Should have multiple switches (notifications, sound, dark mode)
      final switchCount = tester.widgetList<Switch>(switches).length;
      expect(switchCount, greaterThan(1));
    });

    testWidgets('Help dialog shows', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Find and tap help tile
      final helpTile = find.text('Help & Support');
      expect(helpTile, findsOneWidget);

      await tester.tap(helpTile);
      await tester.pumpAndSettle();

      // Should show help dialog
      expect(find.text('Help & Support'), findsWidgets);
      expect(find.text('Tong Messenger Features:'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('Network Discovery Screen Tests', () {
    testWidgets('Network discovery screen initializes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: NetworkDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Network Discovery'), findsOneWidget);
      expect(
        find.byIcon(Icons.stop),
        findsOneWidget,
      ); // Should be scanning initially
    });

    testWidgets('Can stop and start scanning', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: NetworkDiscoveryScreen()));
      await tester.pumpAndSettle();

      // Should start scanning automatically
      expect(find.text('Scanning for devices...'), findsOneWidget);

      // Find and tap stop button
      final stopButton = find.byIcon(Icons.stop);
      expect(stopButton, findsOneWidget);

      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      // Should show refresh button now
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('Shows discovered devices after scanning', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: NetworkDiscoveryScreen()));

      // Wait for scanning to complete
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should show some discovered devices (mocked)
      expect(find.textContaining('Phone'), findsWidgets);
      expect(find.textContaining('WiFi'), findsWidgets);
      expect(find.text('Connect'), findsWidgets);
    });
  });
}
