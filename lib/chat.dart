import 'package:flutter/material.dart';
import 'geminiService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Geminiservice _geminiService = Geminiservice();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _personalityData;
  
  List<String> options = [ 
    "I’m feeling unwell, Please cheer me up!", 
    "I need motivation to get ready in the morning!", 
    "Give me some positive thoughts!", 
    "How can I stay motivated?", 
    "Any tips to stay positive?", 
  ];

  String _userId = "";
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndMessages();
  }

  Future<void> _loadUserDataAndMessages() async {
    await loadUserID();
    if (_userId.isNotEmpty) {
      await _loadMessages(); 
      if (_messages.isEmpty) {
        _addInitialBotMessage();
      }
    }
  }

  Future<void> loadUserID() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('uid') ?? "";
    });
  }

  Future<void> _addInitialBotMessage() async {
    final initialMessage = {
      "text": "Hello, I’m PositiveBot! 👋 I’m your personal virtual encourager. How may I encourage you?",
      "isBot": true,
      'timestamp': FieldValue.serverTimestamp(),
    };
    setState(() {
      _messages.add(initialMessage);
    });
    if (_userId.isNotEmpty) {
      await _firestore
          .collection('user')
          .doc(_userId)
          .collection('chatHistory')
          .add(initialMessage);
    }
  }


  Future<void> _loadMessages() async {
    if (_userId.isNotEmpty) {
      try {
        final QuerySnapshot messagesQuery = await _firestore
            .collection('user')
            .doc(_userId)
            .collection('chatHistory')
            .orderBy('timestamp') 
            .get();

        setState(() {
          _messages = messagesQuery.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        });
      } catch (e) {
        print('Error loading messages: $e');
      }
    }
  }

  Future<void> _loadPersonalityData() async {
  if (_userId.isNotEmpty) {
    try {
      final QuerySnapshot personalityQuery = await _firestore
          .collection('personalityTest')
          .where('userId', isEqualTo: _userId) 
          .get();

      if (personalityQuery.docs.isNotEmpty) {
        setState(() {
          _personalityData = personalityQuery.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        print("No personality document found for this user.");
      }
    } catch (e) {
      print('Error loading personality data: $e');
    }
  }
}

  void _sendMessage(String text) async {
    if (_userId.isEmpty) return;

    final userMessage = {"text": text, "isBot": false, 'timestamp': FieldValue.serverTimestamp()};

    String personalityString = "";
    if (_personalityData != null) {
        personalityString = "Extraversion: ${_personalityData!['Extraversion']}, Agreeableness: ${_personalityData!['Agreeableness']}, Emotional Stability: ${_personalityData!['Emotional Stability']}, Conscientiousness: ${_personalityData!['Conscientiousness']}, Openness to Experience: ${_personalityData!['Openness to Experience']}";
    }
    print(personalityString);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    try {
      await _firestore
          .collection('user')
          .doc(_userId)
          .collection('chatHistory')
          .add(userMessage);

      
      String response = await _geminiService.sendMessage(_userId, _messages, personalityString);

      final botMessage = {"text": response, "isBot": true, 'timestamp': FieldValue.serverTimestamp()};

      setState(() {
        _messages.add(botMessage);
      });

      await _firestore
          .collection('user')
          .doc(_userId)
          .collection('chatHistory')
          .add(botMessage);
        _loadMessages();
    } catch (e) {
      print("Error sending/saving message: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.smart_toy, color: Colors.blue),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PositiveBot", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                Text("Always active", style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isBot = _messages[index]["isBot"];
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.grey[200] : Colors.blue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _messages[index]["text"],
                      style: TextStyle(color: isBot ? Colors.black : Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
            if (!_isLoading && _messages.isNotEmpty && _messages.last['isBot'] == true)
            Padding(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: () => _sendMessage(option),
                        child: Text(option, style: TextStyle(color: Colors.white)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}