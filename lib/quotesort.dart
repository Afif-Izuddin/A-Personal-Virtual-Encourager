import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getSkewedQuotes(String userId, List<String> userPreferences, List<String> userTraits) async {
  try {
    final quotesQuery = await FirebaseFirestore.instance.collection('quoteDB').get();
    List<Map<String, dynamic>> allQuotes = quotesQuery.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    allQuotes.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      if (userPreferences.isNotEmpty) {
        if (a['tag'] != null && userPreferences.contains(a['tag'])) {
          scoreA += 2;
        }
        if (b['tag'] != null && userPreferences.contains(b['tag'])) {
          scoreB += 2;
        }
      }

      if (userTraits.isNotEmpty) {
        if (a['personality'] != null && userTraits.contains(a['personality'])) {
          scoreA += 1;
        }
        if (b['personality'] != null && userTraits.contains(b['personality'])) {
          scoreB += 1;
        }
      }

      scoreA += Random().nextInt(3); 
      scoreB += Random().nextInt(3);

      return scoreB.compareTo(scoreA);
    });

    return allQuotes;
  } catch (e) {
    print("Error getting quotes: $e");
    return [];
  }
}

Future<List<String>> getTopTraits(String userId) async {
  try {
    final personalityTestQuery = await FirebaseFirestore.instance
        .collection('personalityTest')
        .where('userID', isEqualTo: userId)
        .limit(1)
        .get();

    if (personalityTestQuery.docs.isEmpty) {
      return []; 
    }

    final personalityData = personalityTestQuery.docs.first.data() as Map<String, dynamic>;

    List<MapEntry<String, dynamic>> entries = personalityData.entries.toList();

    entries.sort((a, b) => (b.value as num).compareTo(a.value as num));

    List<String> topTraits = [];
    int count = 0;
    for (var entry in entries) {
      if (entry.key != 'userID' && entry.key != 'user') { 
        topTraits.add(entry.key);
        count++;
        if (count == 3) break; 
      }
    }
    return topTraits;
  } catch (e) {
    print("Error getting top traits: $e");
    return [];
  }
}