import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hive_service.dart'; // Ensure this path is correct
import 'firebaseService.dart'; // <--- IMPORTANT: Ensure this path is correct and file exists
import 'main.dart'; // <--- Corrected import for QuoteScreen

class OnboardingResultsScreen extends StatefulWidget {
  @override
  _OnboardingResultsScreenState createState() => _OnboardingResultsScreenState();
}

class _OnboardingResultsScreenState extends State<OnboardingResultsScreen> {
  Map<String, dynamic>? personalityResults;
  final HiveService _hiveService = HiveService();
  final FirebaseService _firebaseService = FirebaseService(); // <--- ADDED: FirebaseService instance
  String? _currentUserId;
  bool _isGuest = false; // <--- ADDED: Variable to store guest status

  // Personality Trait Explanations (unchanged)
  final Map<String, Map<String, String>> _traitExplanations = {
    'Extraversion': {
      'high': 'You tend to be outgoing, energetic, and sociable. You enjoy being around people and are often seen as enthusiastic and assertive.',
      'low': 'You tend to be more reserved, quiet, and reflective. You may prefer solitude or smaller groups and are more comfortable in less stimulating environments.',
    },
    'Agreeableness': {
      'high': 'You are generally cooperative, compassionate, and trusting. You value harmony and tend to be altruistic, empathetic, and kind.',
      'low': 'You tend to be more assertive, competitive, and skeptical. You may prioritize your own interests and are not afraid to challenge others or express dissent.',
    },
    'Conscientiousness': {
      'high': 'You are organized, responsible, and diligent. You tend to be disciplined, goal-oriented, and reliable, often excelling in planning and execution.',
      'low': 'You tend to be more spontaneous, flexible, and less structured. You might be seen as easygoing, but can sometimes be perceived as careless or disorganized.',
    },
    'Emotional Stability': { // This trait is often inversely related to Neuroticism (low neuroticism = high emotional stability)
      'high': 'You tend to be calm, resilient, and emotionally stable. You handle stress well and are less prone to negative emotions like anxiety, anger, or mood swings.',
      'low': 'You may experience a wider range of emotions, including anxiety, worry, and mood swings. You might be more sensitive to stress and external pressures, and can be easily upset.',
    },
    'Openness to Experience': {
      'high': 'You are imaginative, curious, and open to new ideas and experiences. You enjoy variety, intellectual pursuits, and appreciate art, adventure, and unusual ideas.',
      'low': 'You tend to be more conventional, practical, and prefer routine. You may be resistant to change, prefer familiar ways of doing things, and find comfort in tradition.',
    },
  };

  // Define the expected personality traits for display order and filtering (unchanged)
  final List<String> _displayOrderTraits = [
    'Extraversion',
    'Agreeableness',
    'Conscientiousness',
    'Emotional Stability',
    'Openness to Experience',
  ];

  @override
  void initState() {
    super.initState();
    _loadPersonalityResults();
  }

  Future<void> _loadPersonalityResults() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('uid');
    _isGuest = prefs.getBool('isGuest') ?? false; // <--- ADDED: Retrieve guest status

    // --- CRUCIAL DEBUGGING PRINTS (Keep these for now to verify behavior) ---
    print('DEBUG: --- OnboardingResultsScreen Loading Data ---');
    print('DEBUG: Current User ID from SharedPreferences: $_currentUserId');
    print('DEBUG: Is Guest User from SharedPreferences: $_isGuest');
    // --- END DEBUGGING PRINTS ---

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print('ERROR: User ID is null or empty. Cannot load personality results.');
      // Handle this case, e.g., navigate to login/onboarding start
      return;
    }

    Map<String, dynamic>? data;

    try {
      if (_isGuest) { // <--- ADDED: Conditional logic for guest vs. logged-in
        print('DEBUG: Attempting to load personality data from HIVE for user: $_currentUserId');
        data = await _hiveService.getPersonalityTestResults(_currentUserId!);
        if (data == null) {
          print('DEBUG: No personality data found in Hive for $_currentUserId.');
        } 
         else {
           print('DEBUG: Successfully loaded personality data from Hive for $_currentUserId.');
        }
      } else { // <--- ADDED: Firebase loading for non-guest users
        print('DEBUG: Attempting to load personality data from FIREBASE for user: $_currentUserId');
        data = await _firebaseService.getPersonalityData(_currentUserId!);
        if (data == null) {
          print('DEBUG: No personality data found in Firebase for $_currentUserId.');
        } 
        else {
          print('DEBUG: Successfully loaded personality data from Firebase for $_currentUserId.');
        }
      }
    } catch (e) {
      print('ERROR: Exception during personality data loading: $e');
      data = null; // Clear results on error
    }

    setState(() {
      personalityResults = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Personality Insights!'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Congratulations on completing your TIPI Test!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Here are your initial personality insights:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            if (personalityResults != null)
              _buildPersonalityResultsDisplay(personalityResults!)
            else
              const Center(child: CircularProgressIndicator()), // Show loading or error
            SizedBox(height: 30),

            Text(
              'To further personalize your experience, you can add details like your gender, beliefs, and date of birth in your **Profile Settings**.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),

            Text(
              'You can also refine the content you see by adjusting your topic preferences in the **Preferences** section, also found in your Profile Settings.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => QuoteScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Continue to App'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityResultsDisplay(Map<String, dynamic> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _displayOrderTraits.map((traitName) {
        if (!results.containsKey(traitName) || results[traitName] == null) {
          return const SizedBox.shrink();
        }

        final dynamic value = results[traitName];

        double score;
        if (value is num) {
          score = value.toDouble();
        } else if (value is String) {
          score = double.tryParse(value) ?? 0.0;
        } else {
          score = 0.0;
        }

        String explanationText = '';
        if (_traitExplanations.containsKey(traitName)) {
          if (score >= 4.0) {
            explanationText = _traitExplanations[traitName]!['high']!;
          } else {
            explanationText = _traitExplanations[traitName]!['low']!;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$traitName: ${score.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 5),
              Text(
                explanationText,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}