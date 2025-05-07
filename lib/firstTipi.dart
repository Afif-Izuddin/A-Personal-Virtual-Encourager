import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class FirstPersonalityTestScreen extends StatefulWidget {
  @override
  _PersonalityTestScreenState createState() => _PersonalityTestScreenState();
}

class _PersonalityTestScreenState extends State<FirstPersonalityTestScreen> {
  int _currentQuestionIndex = 0;
  List<int?> _answers = List.filled(10, null);
  bool _hasAnswered = false;

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

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String _userId = " ";

  Future<void> loadUserID() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _userId = prefs.getString('uid') ?? "assets/background1.jpg"; 
  });
  print(_userId);
  }

   @override
  void initState() {
    super.initState;
    loadUserID();
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

  void _handleSubmit(List<int?> answers) {
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
      'userID' : _userId,
      'Extraversion': extraversion,
      'Agreeableness': agreeableness,
      'Conscientiousness': conscientiousness,
      'Emotional Stability': emotionalStability,
      'Openness to Experience': openness,
    };

    _sendAnswersToFirestore(personalityScores);

    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => QuoteScreen()),
                    );
  }

  Future<void> _sendAnswersToFirestore(Map<String, dynamic> data) async {
    final personalityTestCollection = firestore.collection('personalityTest');

    try {
      final querySnapshot =
          await personalityTestCollection.where('userID', isEqualTo: _userId).get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await personalityTestCollection.doc(docId).update(data);
        print('Personality scores updated in Firestore!');
      } else {
        
        await personalityTestCollection.add(data);
        print('Personality scores added to Firestore!');
      }
    } catch (e) {
      print('Error sending personality scores to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving personality scores')),
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
        leading: null,
        automaticallyImplyLeading: false,
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
              children: List.generate(7, (index) {
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (index == 0)
                          Text("Disagree Strongly ",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Expanded(
                          child: Center(
                            child: Text((index + 1).toString(),
                                style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        if (index == 6)
                          Text(" Agree Strongly",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              }),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _currentQuestionIndex < _questions.length - 1
                  ? _nextQuestion
                  : () {
                      if (!_hasAnswered) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select an answer, $_userId')),
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