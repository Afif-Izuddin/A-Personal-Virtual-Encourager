import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String appSettingsBox = 'appSettings';
  static const String personalityTestResultsBox = 'personalityTestResults';
  static const String userPreferencesBox = 'userPreferences';
  static const String savedQuoteBox = 'savedQuotes';
  static const String chatMessagesBox = 'chatMessages'; 
  static const String alarmsBox = 'alarmsBox';
  static const String userProfileBox = 'userProfile'; 

  static Future<void> initializeHive() async {
    await Hive.initFlutter();
    await openAppSettingsBox();
    await openPersonalityTestResultsBox();
    await openUserPreferencesBox();
    await openSavedQuoteBox();
    await openChatMessagesBox();
    await openAlarmsBox();
    await openUserProfileBox(); 
  }

  static Future<Box> openAppSettingsBox() async {
    return await Hive.openBox(appSettingsBox);
  }

  static Box getAppSettingsBox() {
    return Hive.box(appSettingsBox);
  }

  static Future<Box> openPersonalityTestResultsBox() async {
    return await Hive.openBox(personalityTestResultsBox);
  }

  static Box getPersonalityTestResultsBox() {
    return Hive.box(personalityTestResultsBox);
  }

  static Future<Box> openUserPreferencesBox() async {
    return await Hive.openBox(userPreferencesBox);
  }

  static Box getUserPreferencesBox() {
    return Hive.box(userPreferencesBox);
  }

  static Future<Box> openSavedQuoteBox() async {
    return await Hive.openBox(savedQuoteBox);
  }

  static Box getSavedQuoteBox() {
    return Hive.box(savedQuoteBox);
  }

  static Future<Box> openChatMessagesBox() async {
    return await Hive.openBox(chatMessagesBox);
  }

  static Box getChatMessagesBox() {
    return Hive.box(chatMessagesBox);
  }

  static Future<Box> openUserProfileBox() async {
    return await Hive.openBox(userProfileBox);
  }

  static Box getUserProfileBox() {
    return Hive.box(userProfileBox);
  }

  Future<void> saveGuestStatus(bool isGuest) async {
    final box = getAppSettingsBox();
    await box.put('isGuest', isGuest);
  }

  bool isGuestUser() {
    final box = getAppSettingsBox();
    return box.get('isGuest', defaultValue: false);
  }

  Future<void> savePersonalityTestResults(String userId, Map<String, dynamic> data) async {
    final box = getPersonalityTestResultsBox();
    await box.put(userId, data);
    print('Personality scores saved to Hive for user: $userId');
  }

  Map<String, dynamic>? getPersonalityTestResults(String userId) {
    final box = getPersonalityTestResultsBox();
    final dynamic rawData = box.get(userId);

    if (rawData is Map) {
      final Map<String, dynamic> safeData = {};
      rawData.forEach((key, value) {
        safeData[key.toString()] = value;
      });
      return safeData as Map<String, dynamic>;
    } else {
      print('Warning: Personality data for user $userId from Hive is not a Map.');
      return {}; 
    }
  }

   Future<bool> doesPersonalityTestExist(String userId) async {
    final box = getPersonalityTestResultsBox();
    return box.containsKey(userId); // Check if the box contains an entry for the userId
  }

  Future<void> saveUserPreferences(String userId, List<String> preferences) async {
    final box = getUserPreferencesBox();
    await box.put(userId, preferences);
    print('User preferences saved to Hive for user: $userId: $preferences');
  }

  Future<List<String>?> getUserPreferences(String userId) async {
    final box = getUserPreferencesBox();
    return box.get(userId)?.cast<String>().toList();
  }

  Future<void> saveQuote(String userId, String quoteText, String author) async {
    final box = getSavedQuoteBox();
    final key = '${userId}_${quoteText.hashCode}_${author.hashCode}';
    await box.put(key, {'quoteText': quoteText, 'author': author});
    print('Quote saved to Hive for user: $userId: "$quoteText" - $author');
  }

  Future<List<Map<String, String>>?> getSavedQuotes(String userId) async {
    final box = getSavedQuoteBox();
    List<Map<String, String>> saved = [];
    for (int i = 0; i < box.length; i++) {
      final key = box.keyAt(i);
      if (key is String && key.startsWith('${userId}_')) {
        final quoteData = box.getAt(i);
        if (quoteData is Map) {
          saved.add({'quoteText': quoteData['quoteText'], 'author': quoteData['author']});
        }
      }
    }
    return saved;
  }

  Future<void> deleteSavedQuote(String userId, String quoteText, String author) async {
    final box = getSavedQuoteBox();
    final keyToDelete = '${userId}_${quoteText.hashCode}_${author.hashCode}';
    await box.delete(keyToDelete);
    print('Quote deleted from Hive for user: $userId: "$quoteText" - $author');
  }

  Future<void> addChatMessage(String userId, Map<String, dynamic> message) async {
    final box = getChatMessagesBox();
    final chatList = box.get(userId) as List<dynamic>? ?? [];
    chatList.add(message);
    await box.put(userId, chatList);
    print('Chat message added to Hive for user: $userId: $message');
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId) async {
    final box = getChatMessagesBox();
    final dynamic rawChatList = box.get(userId);
    List<Map<String, dynamic>> safeChatList = [];

    if (rawChatList is List) {
      for (var item in rawChatList) {
        if (item is Map) {
          Map<String, dynamic> safeMessage = {};
          item.forEach((key, value) {
            safeMessage[key.toString()] = value;
          });
          safeChatList.add(safeMessage);
        } else {
          print('Warning: Invalid chat message item in Hive for user $userId: $item');
        }
      }
    } else {
      print('Warning: Chat messages for user $userId from Hive is not a List.');
    }

    return safeChatList;
  }

  Future<void> clearChatMessages(String userId) async {
    final box = getChatMessagesBox();
    await box.delete(userId);
    print('Chat messages cleared for user: $userId');
  }

  static Future<Box> openAlarmsBox() async {
    return await Hive.openBox(alarmsBox);
  }

  static Box getAlarmsBox() {
    return Hive.box(alarmsBox);
  }

  Future<void> saveUserProfile(String userId, Map<String, dynamic> profileData) async {
    final box = getUserProfileBox();
    await box.put(userId, profileData);
    print('User profile saved to Hive for user: $userId: $profileData');
  }

  Map<String, dynamic>? getUserProfile(String userId) {
    final box = getUserProfileBox();
    final dynamic rawData = box.get(userId);
    if (rawData is Map) {
      return rawData.cast<String, dynamic>();
    } else {
      print('Warning: User profile data for user $userId from Hive is not a Map.');
      return null;
    }
  }
}