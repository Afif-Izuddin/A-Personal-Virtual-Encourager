import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_a_personal_virtual_encourager_test_1/settingScreen.dart'; // Replace with your path
import 'package:fyp_a_personal_virtual_encourager_test_1/changeBackground.dart'; // Import BackgroundScreen

void main() {
  group('SettingsScreen Tests', () {
    testWidgets('Renders settings options with correct icons', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));

      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Change your background for the daily quotes here'), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsNWidgets(3)); // Check for the icon in all 3 options

      expect(find.text('Reminder'), findsOneWidget);
      expect(find.text('Set and get your notification with encouragement'), findsOneWidget);

      expect(find.text('Widgets'), findsOneWidget);
      expect(find.text('Adjust or add widgets to your home screen'), findsOneWidget);
    });

    testWidgets('Navigates to BackgroundScreen on tap', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsScreen()));

      final backgroundGestureDetector = find.byType(GestureDetector).at(0); 

      await tester.tap(backgroundGestureDetector);
      await tester.pumpAndSettle();

      expect(find.byType(BackgroundScreen), findsOneWidget);
    });
  });
}