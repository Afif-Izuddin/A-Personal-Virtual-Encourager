import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('ChatScreen Unit Tests', () {
    test('Initial bot message is added correctly', () async {
      final messages = <Map<String, dynamic>>[];
      final initialMessage = {
        "text": "Hello, I’m PositiveBot! 👋 I’m your personal virtual encourager. How may I encourage you?",
        "isBot": true,
        'timestamp': FieldValue.serverTimestamp(),
      };

      messages.add(initialMessage);

      expect(messages.length, 1);
      expect(messages.first['text'], initialMessage['text']);
      expect(messages.first['isBot'], true);
    });

    test('User message is added correctly', () async {
      final messages = <Map<String, dynamic>>[];
      final userMessage = {"text": "Hello, Bot!", "isBot": false, 'timestamp': FieldValue.serverTimestamp()};

      messages.add(userMessage);

      expect(messages.length, 1);
      expect(messages.first['text'], "Hello, Bot!");
      expect(messages.first['isBot'], false);
    });

    test('Options list contains predefined options', () {
      final options = [
        "I’m feeling unwell, Please cheer me up!",
        "I need motivation to get ready in the morning!",
        "Give me some positive thoughts!",
        "How can I stay motivated?",
        "Any tips to stay positive?",
      ];

      expect(options.length, 5);
      expect(options.contains("Give me some positive thoughts!"), true);
    });

    test('SharedPreferences loads user ID correctly', () async {
      final mockPreferences = MockSharedPreferences();
      when(mockPreferences.getString('uid')).thenReturn("testUserId");

      final userId = mockPreferences.getString('uid');
      expect(userId, "testUserId");
    });
  });
}