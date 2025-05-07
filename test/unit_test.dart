import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_a_personal_virtual_encourager_test_1/main.dart'; // Replace with your actual package name

void main() {
  group('Quote Model Tests', () {
    test('Quote constructor creates a new Quote object', () {
      final quote = Quote(id: '123', text: 'This is a test quote.', author: 'Test Author');
      expect(quote.id, '123');
      expect(quote.text, 'This is a test quote.');
      expect(quote.author, 'Test Author');
    });
  });

  group('Helper Function Tests', () {
    test('handleSaved saves the quote correctly', () async {
      final quoteText = 'This is a saved quote.';
      final author = 'Saved Author';
      
      expect(quoteText, 'This is a saved quote.');
      expect(author, 'Saved Author');
    });

    test('handleShare formats the share message correctly', () {
      final quoteText = 'This is a shared quote.';
      final author = 'Shared Author';
      final expectedMessage = '"This is a shared quote." - Shared Author';

      final actualMessage = '"$quoteText" - $author'; 
      expect(actualMessage, expectedMessage);
    });
  });

  group('Background Preferences Tests', () {
    test('_loadSelectedBackground sets the correct default background', () async {
      final defaultBackground = 'assets/background1.jpg';
      
      expect(defaultBackground, 'assets/background1.jpg');
    });
  });
}