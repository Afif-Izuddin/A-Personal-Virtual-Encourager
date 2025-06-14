import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hive_service.dart';
import 'firebaseService.dart';

class Geminiservice {
  final HiveService _hiveService = HiveService();
  final FirebaseService _firebaseService = FirebaseService();

  final model = GenerativeModel(
    model: 'gemini-2.0-flash-exp',
    apiKey: "AIzaSyDP1SWcnHQmvtPfmnsTudNKRVZAuE7P7O8",
    generationConfig: GenerationConfig(
      temperature: 1,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 8192,
      responseMimeType: 'text/plain',
    ),
    systemInstruction: Content.system(
      'Your response must Only be the response see the example below and stick to it DO NOT INCLUDE "" (string, containing the quote, song title with artist, or encouraging message). Ensure any author/artist is included within the "text" field, e.g., "Quote text - Author" or "Song Title - Artist".\n\n'
      'Do note that YOU can and SHOULD respond with one of these: Motivational/Encouraging Message, Quote, Song Recommendation. DO Alternate some times\n'
      'Example response for a quote:\n'
      'The only way to do great work is to love what you do. - Steve Jobs\n'
      'Example response for a song:\n'
      'Here is a song for you: Imagine - John Lennon\n'
      'With that in mind, you are to provide a motivational quote, song title, or encouragement. Take into account the user\'s:\n'
      '1. Personality profile (included in the prompt).\n'
      '2. Beliefs (included in the prompt, may be "Not specified").\n'
      '3. Age (included in the prompt, may be "Not specified" or a calculated number).\n' // Updated description
      '4. Gender (included in the prompt, may be "Not specified").\n'
      '5. The current situation or last message (included in the prompt).\n'
      'Provide a response that feels appropriate for that type of person and situation, Focus on the situation first, Personality second then the other, Do respond with the appropriate beliefs teachings but do not make it too strong or include it in every response.'
      'Do not Repeat responses.'
    ),
  );

  Future<String> sendMessage(String userId, List<Map<String, dynamic>> messages, String personalityProfile) async {
    try {
      final chatHistory = await _getChatHistoryFromFirestore(userId);
      final userProfile = await _getUserProfileData(userId);

      final geminiHistory = chatHistory.map((message) {
        final part = TextPart(message["text"]);
        return message["isBot"] ? Content.model([part]) : Content.multi([part]);
      }).toList();

      String formattedMessages = messages.map((m) => "${m["isBot"] ? "bot" : "user"}: ${m["text"]}").join("\n");
      String situation = messages.isNotEmpty ? messages.last["text"] : "";

      // --- MODIFIED: Extracting beliefs, CALCULATING age from dob, and gender ---
      final String beliefs = userProfile['belief']?.toString() ?? 'Not specified'; // Used 'belief' as per your UI code
      final String dobString = userProfile['dob']?.toString() ?? ''; // Get dob string
      final String gender = userProfile['gender']?.toString() ?? 'Not specified';

      String age;
      if (dobString.isNotEmpty) {
        final DateTime? dob = DateTime.tryParse(dobString);
        if (dob != null) {
          final DateTime now = DateTime.now();
          int calculatedAge = now.year - dob.year;
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
            calculatedAge--; 
          }
          age = calculatedAge.toString();
        } else {
          age = 'Not specified'; 
        }
      } else {
        age = 'Not specified'; 
      }
      

      final prompt =
          'the user\'s personality profile:[\n$personalityProfile\n]\n'
          'user\'s beliefs: "$beliefs"\n'
          'user\'s age: "$age"\n' 
          'user\'s gender: "$gender"\n'
          'situation: "$situation"\n'
          'Chat History:\n$formattedMessages';

      final content = Content.text(prompt);

      final chat = model.startChat(history: geminiHistory);

      final response = await chat.sendMessage(content);

      if (response.candidates.isNotEmpty) {
        final candidate = response.candidates.first;

        String responseText = candidate.content.parts
            .whereType<TextPart>()
            .map((p) => p.text)
            .join();

        try {
          final decodedResponse = jsonDecode(responseText);
          final type = decodedResponse['type'];
          final text = decodedResponse['text'];
          return "[$type]\n$text";
        } catch (_) {
          print('WARNING: Gemini response was not valid JSON, returning raw text: $responseText');
          return responseText;
        }
      }

      return "No response from Gemini.";
    } catch (e) {
      print('Error sending message to Gemini: $e');
      return "Error communicating with Gemini.";
    }
  }

  Future<Map<String, dynamic>> _getUserProfileData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isGuest = prefs.getBool('isGuest') ?? false;

    try {
      if (isGuest) {
        final Map<String, dynamic>? guestProfile = await _hiveService.getUserProfile(userId);
        return guestProfile ?? {};
      } else {
        final Map<String, dynamic> firebaseProfile = await _firebaseService.getUserProfile(userId);
        return firebaseProfile;
      }
    } catch (e) {
      print('Error loading user profile data: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getChatHistoryFromFirestore(String userId) async {
    try {
      final QuerySnapshot messagesQuery = await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('chatHistory')
          .orderBy('timestamp')
          .limitToLast(15)
          .get();

      return messagesQuery.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error loading chat history from Firestore: $e');
      return [];
    }
  }
}