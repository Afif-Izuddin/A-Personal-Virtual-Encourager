import 'package:flutter/material.dart';
import 'firebaseService.dart'; 
import 'hive_service.dart'; 
import 'normalTipiResultScreen.dart';

class PersonalityTestScreen extends StatefulWidget {
  @override
  _PersonalityTestScreenState createState() => _PersonalityTestScreenState();
}

class _PersonalityTestScreenState extends State<PersonalityTestScreen> {
  int _currentQuestionIndex = 0;
  List<int?> _answers = List.filled(10, null);
  bool _hasAnswered = false;
  String _userId = "";
  bool _isGuest = false;
  final FirebaseService _firebaseService = FirebaseService(); 
  final HiveService _hiveService = HiveService(); 

  final List<String> _questions = [
    "I see myself as extraverted, enthusiastic.",
    "I see myself as critical, quarrelsome.",
    "I see myself as organized, efficient.",
    "I see myself as anxious, easily upset.",
    "I see myself as imaginative, creative.",
    "I see myself as reserved, quiet.",
    "I see myself as sympathetic, warm.",
    "I see myself as disorganized, careless.",
    "I see myself as calm, emotionally stable.",
    "I see myself as conventional, uncreative.",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndGuestStatus();
  }

  Future<void> _loadUserIdAndGuestStatus() async {
    final userId = await _firebaseService.getCurrentUserId();
    final isGuestStatus = await _firebaseService.getGuestStatus();
    setState(() {
      _userId = userId ?? "";
      _isGuest = isGuestStatus;
    });
    print('User ID: $_userId, Is Guest: $_isGuest');
  }

  void _answerQuestion(int value) {
    setState(() {
      _answers[_currentQuestionIndex] = value;
      _hasAnswered = true;
    });
  }

  void _nextQuestion() {
    if (!_hasAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an answer')),
      );
      return;
    }
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _hasAnswered = false;
      }
    });
  }

  void _handleSubmit(List<int?> answers) async {
    if (answers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    List<int> nonNullAnswers = answers.cast<int>();

    double extraversion = (nonNullAnswers[0] + (8 - nonNullAnswers[5])) / 2;
    double agreeableness = ((8 - nonNullAnswers[1]) + nonNullAnswers[6]) / 2;
    double conscientiousness = (nonNullAnswers[2] + (8 - nonNullAnswers[7])) / 2;
    double emotionalStability = ((8 - nonNullAnswers[3]) + nonNullAnswers[8]) / 2;
    double openness = (nonNullAnswers[4] + (8 - nonNullAnswers[9])) / 2;

    Map<String, dynamic> personalityScores = {
      'userID': _userId,
      'Extraversion': extraversion,
      'Agreeableness': agreeableness,
      'Conscientiousness': conscientiousness,
      'Emotional Stability': emotionalStability,
      'Openness to Experience': openness,
    };

    if (!_isGuest) {
      _sendAnswersToFirestore(personalityScores);
    } else {
      _saveAnswersToHive(personalityScores);
    }

   Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => NormalTipiResultsScreen()),
    );
  }

  Future<void> _sendAnswersToFirestore(Map<String, dynamic> data) async {
    try {
      await _firebaseService.savePersonalityScores(_userId, data);
    } catch (e) {
      print('Error sending personality scores in UI: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving personality scores')),
      );
    }
  }

  Future<void> _saveAnswersToHive(Map<String, dynamic> data) async {
    try {
      await _hiveService.savePersonalityTestResults(_userId, data);
      print('Personality scores saved to Hive for guest user: $_userId');
    } catch (e) {
      print('Error saving personality scores to Hive: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving personality scores locally')),
      );
    }
  }

  double _calculateProgress() {
    return (_currentQuestionIndex + 1) / _questions.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text("Personality Test", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: _calculateProgress(),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 20),
            Text(
              "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Text(
              _questions[_currentQuestionIndex],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),
            Column(
              children: [
                Text("Strongly Disagree", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ...List.generate(7, (index) {
                  return GestureDetector(
                    onTap: () => _answerQuestion(index + 1),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _answers[_currentQuestionIndex] == index + 1
                            ? Colors.blue[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _answers[_currentQuestionIndex] == index + 1
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text((index + 1).toString(),
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  );
                }),
                Text("Strongly Agree", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _currentQuestionIndex < _questions.length - 1
                  ? _nextQuestion
                  : () {
                      if (!_hasAnswered) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select an answer')),
                        );
                        return;
                      }
                      _handleSubmit(_answers);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _currentQuestionIndex < _questions.length - 1 ? "Next →" : "Submit!",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}