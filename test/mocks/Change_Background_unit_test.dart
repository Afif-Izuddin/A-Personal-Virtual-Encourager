import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp_a_personal_virtual_encourager_test_1/changeBackground.dart';

void main() {
  group('BackgroundScreen Widget Tests', () {
    testWidgets('BackgroundScreen renders background options', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({}); 

      await tester.pumpWidget(MaterialApp(home: BackgroundScreen()));
      await tester.pumpAndSettle(); 

      expect(find.text('Background'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}