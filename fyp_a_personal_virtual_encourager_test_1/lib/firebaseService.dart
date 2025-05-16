import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'dart:math';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> createUserDocument(User user, String username) async {
    try {
      await _firestore.collection('user').doc(user.uid).set({
        'username': username,
        'preference': [],
      });
    } catch (e) {
      print('Error creating user document: $e');
      throw e; // Re-throw the error to be caught in the UI
    }
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }

  Future<void> saveGuestStatus(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', isGuest);
  }

  Future<bool> getGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuest') ?? false;
  }

  Future<void> saveUserId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
  }

  Future<bool> checkIfPersonalityTestCompleted(String userId) async {
    try {
      final personalityTestQuery = await _firestore
          .collection('personalityTest')
          .where('userID', isEqualTo: userId)
          .limit(1)
          .get();
      return personalityTestQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking personality test: $e');
      return false; 
    }
  }

   Future<List<String>> getUserPreferences(String userId) async {
    try {
      final userDoc = await _firestore.collection('user').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return List<String>.from(userData['preference'] ?? []);
      } else {
        print("User document not found for preferences.");
        return [];
      }
    } catch (e) {
      print("Error fetching user preferences: $e");
      return [];
    }
  }

  Future<void> saveQuote(String userId, String quoteText, String author) async {
    try {
      await _firestore.collection('savedQuote').add({
        'userID': userId,
        'quoteText': quoteText,
        'author': author,
      });
      print('Quote saved successfully!');
    } catch (e) {
      print('Error saving quote: $e');
      throw e; // Re-throw for UI handling
    }
  }

  Future<String?> getSelectedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedBackground');
  }

  Future<void> setSelectedBackground(String backgroundPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBackground', backgroundPath);
  }

  Future<List<Quote>> fetchSavedQuotes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('savedQuote')
          .where('userID', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Quote(
          id: doc.id,
          text: data['quoteText'] as String,
          author: data['author'] as String,
        );
      }).toList();
    } catch (e) {
      print("Error fetching saved quotes: $e");
      throw e; // Re-throw for UI handling
    }
  }

  Future<void> deleteSavedQuote(String quoteId) async {
    try {
      await _firestore.collection('savedQuote').doc(quoteId).delete();
    } catch (e) {
      print("Error deleting quote: $e");
      throw e; // Re-throw for UI handling
    }
  }

  Future<List<String>> getUserPreferenceList(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('user').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return List<String>.from(userData['preference'] ?? []);
      } else {
        print("User document not found for preferences.");
        return [];
      }
    } catch (e) {
      print("Error fetching preferences: $e");
      throw e; // Re-throw for UI handling
    }
  }

  Future<void> updateUserPreferences(String userId, List<String> preferences) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'preference': preferences,
      });
    } catch (e) {
      print("Error updating preferences: $e");
      throw e; // Re-throw for UI handling
    }
  }

  Future<void> savePersonalityScores(String userId, Map<String, dynamic> scores) async {
    final personalityTestCollection = _firestore.collection('personalityTest');

    try {
      final querySnapshot =
          await personalityTestCollection.where('userID', isEqualTo: userId).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        final docId = querySnapshot.docs.first.id;
        await personalityTestCollection.doc(docId).update(scores);
        print('Personality scores updated in Firestore!');
      } else {
        // Create new document
        await personalityTestCollection.add(scores);
        print('Personality scores added to Firestore!');
      }
    } catch (e) {
      print('Error sending personality scores to Firestore: $e');
      throw e; // Re-throw for UI handling
    }
  }

  Future<String?> getUsername(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('user').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['username'] as String?;
      } else {
        print("User document not found for ID: $userId");
        return null;
      }
    } catch (e) {
      print("Error fetching username: $e");
      throw e; // Re-throw for UI handling
    }
  }

  Future<void> updateUsername(String userId, String newUsername) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'username': newUsername,
      });
      print('Username updated successfully for user: $userId');
    } catch (e) {
      print("Error updating username: $e");
      throw e; // Re-throw for UI handling
    }
  }
  Future<void> addChatMessage(String userId, Map<String, dynamic> message) async {
    try {
      await _firestore
          .collection('user')
          .doc(userId)
          .collection('chatHistory')
          .add(message);
    } catch (e) {
      print("Error adding chat message: $e");
      throw e; // Re-throw for UI handling
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId) async {
    try {
      final QuerySnapshot messagesQuery = await _firestore
          .collection('user')
          .doc(userId)
          .collection('chatHistory')
          .orderBy('timestamp')
          .get();

      return messagesQuery.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error loading messages: $e');
      throw e; // Re-throw for UI handling
    }
  }

  Future<Map<String, dynamic>?> getPersonalityData(String userId) async {
    try {
      final QuerySnapshot personalityQuery = await _firestore
          .collection('personalityTest')
          .where('userID', isEqualTo: userId)
          .get();

      if (personalityQuery.docs.isNotEmpty) {
        return personalityQuery.docs.first.data() as Map<String, dynamic>;
      } else {
        print("No personality document found for user: $userId");
        return null;
      }
    } catch (e) {
      print('Error loading personality data: $e');
      throw e; // Re-throw for UI handling
    }
  }

  Future<Quote?> fetchRandomQuote() async {
    try {
      final CollectionReference quotesCollection = _firestore.collection('quoteDB');
      final QuerySnapshot snapshot = await quotesCollection.get();
      if (snapshot.docs.isNotEmpty) {
        final Random random = Random();
        final int randomIndex = random.nextInt(snapshot.docs.length);
        final DocumentSnapshot randomQuoteDoc = snapshot.docs[randomIndex];
        final String quoteText = randomQuoteDoc.get('quoteText') as String? ?? 'No quote found';
        final String author = randomQuoteDoc.get('author') as String? ?? 'Unknown';
        return Quote(id: randomQuoteDoc.id, text: quoteText, author: author);
      } else {
        print('Error: No quotes found in Firestore.');
        return null;
      }
    } catch (e) {
      print('Error fetching random quote: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(
    String userId,
    String username,
    String? gender, // Expecting encrypted data now
    String? dob,    // Expecting encrypted data now (as String)
    String? belief,  // Expecting encrypted data now
  ) async {
    try {
      await _firestore.collection('user').doc(userId).update({
        'username': username,
        'gender': gender,
        'dob': dob,
        'belief': belief,
      });
      print('User profile updated successfully (encrypted data)!');
    } catch (e) {
      print('Error updating user profile (encrypted data): $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('user').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        print("User document not found for ID: $userId");
        return {};
      }
    } catch (e) {
      print("Error fetching user profile: $e");
      throw e;
    }
  }
  
}