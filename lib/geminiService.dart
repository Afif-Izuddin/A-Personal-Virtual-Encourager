import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Geminiservice {

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
    systemInstruction: Content.system('The following prompt asks you to give a motivational quote, song titles, or encouragement from you. Please reply with only one of those\nand reply with the following pattern do not vary and only send back the pattern\n\n\nwith that in mind these are some things to keep in mind when replying:\n1. their personality profile which will be included in the prompt\n\nplease reply with something you feel like that type of person with the addition of the situation in the prompt properly. Also do note to have an author for example Close to You - the carpenters, or "this is a motivational quote" -King arthur. If you are recommending a song please say with this at the front Here is a song for you: '),
  );

  Future<String> sendMessage(String userId, List<Map<String, dynamic>> messages, String personalityProfile) async {
    try {
      
      final chatHistory = await _getChatHistoryFromFirestore(userId);

      final geminiHistory = chatHistory.map((message) {
        final part = TextPart(message["text"]);
        return message["isBot"] ? Content.model([part]) : Content.multi([part]);
      }).toList();
      
      String formattedMessages = messages.map((m) => "${m["isBot"] ? "bot" : "user"}: ${m["text"]}").join("\n");
      String situation = messages.isNotEmpty ? messages.last["text"] : "";

      final prompt = 'the user\'s personality profile:[\n$personalityProfile\n]\nsituation: "$situation"\nChat History:\n$formattedMessages';

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
          return responseText;
        }
      }

      return "No response from Gemini.";
    } catch (e) {
      print('Error sending message to Gemini: $e');
      return "Error communicating with Gemini.";
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

