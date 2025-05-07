import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      return false; // Or throw the error, depending on your error handling strategy
    }
  }
}