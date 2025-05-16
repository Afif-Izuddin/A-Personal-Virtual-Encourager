import 'package:flutter/material.dart';
import 'geminiService.dart';
import 'firebaseService.dart'; // Import FirebaseService
import 'hive_service.dart'; // Import HiveService

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Geminiservice _geminiService = Geminiservice();
  final FirebaseService _firebaseService = FirebaseService(); // Instantiate FirebaseService
  final HiveService _hiveService = HiveService(); // Instantiate HiveService
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
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndMessages();
  }

  Future<void> _loadUserDataAndMessages() async {
    await _loadUserIdAndGuestStatus();
    if (_userId.isNotEmpty) {
      await _loadMessages();
      if (_messages.isEmpty && !_isGuest) {
        _addInitialBotMessageToFirebase();
      } else if (_messages.isEmpty && _isGuest) {
        _addInitialBotMessageToHive();
      }
      await _loadPersonalityData();
    }
  }

  Future<void> _loadUserIdAndGuestStatus() async {
    final userId = await _firebaseService.getCurrentUserId();
    final isGuestStatus = await _firebaseService.getGuestStatus();
    setState(() {
      _userId = userId ?? "";
      _isGuest = isGuestStatus;
    });
  }

  Future<void> _addInitialBotMessageToFirebase() async {
    final initialMessage = {
      "text": "Hello, I’m PositiveBot! 👋 I’m your personal virtual encourager. How may I encourage you?",
      "isBot": true,
      'timestamp': DateTime.now(), // Use local time for initial message
    };
    setState(() {
      _messages.add(initialMessage);
    });
    if (_userId.isNotEmpty && !_isGuest) {
      try {
        await _firebaseService.addChatMessage(_userId, initialMessage);
      } catch (e) {
        print("Error saving initial bot message to Firebase: $e");
      }
    }
  }

  Future<void> _addInitialBotMessageToHive() async {
    final initialMessage = {
      "text": "Hello, I’m PositiveBot! 👋 I’m your personal virtual encourager. How may I encourage you?",
      "isBot": true,
      'timestamp': DateTime.now(), // Use local time for initial message
    };
    setState(() {
      _messages.add(initialMessage);
    });
    if (_userId.isNotEmpty && _isGuest) {
      try {
        await _hiveService.addChatMessage(_userId, initialMessage);
      } catch (e) {
        print("Error saving initial bot message to Hive: $e");
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_userId.isNotEmpty) {
      try {
        List<Map<String, dynamic>> loadedMessages;
        if (!_isGuest) {
          loadedMessages = await _firebaseService.getChatMessages(_userId);
        } else {
          loadedMessages = await _hiveService.getChatMessages(_userId);
        }
        setState(() {
          _messages = loadedMessages;
        });
      } catch (e) {
        print('Error loading messages in UI: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat history')),
        );
      }
    }
  }

  Future<void> _loadPersonalityData() async {
    if (_userId.isNotEmpty && !_isGuest) {
      try {
        final personalityData = await _firebaseService.getPersonalityData(_userId);
        setState(() {
          _personalityData = personalityData;
        });
      } catch (e) {
        print('Error loading personality data in UI: $e');
      }
    } else if (_userId.isNotEmpty && _isGuest) {
      final personalityData = _hiveService.getPersonalityTestResults(_userId);
      setState(() {
        _personalityData = personalityData;
      });
    }
  }

  void _sendMessage(String text) async {
    if (_userId.isEmpty) return;

    final userMessage = {"text": text, "isBot": false, 'timestamp': DateTime.now()};

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
      if (!_isGuest) {
        await _firebaseService.addChatMessage(_userId, userMessage);
        String response = await _geminiService.sendMessage(_userId, _messages, personalityString);
        final botMessage = {"text": response, "isBot": true, 'timestamp': DateTime.now()};
        setState(() {
          _messages.add(botMessage);
        });
        await _firebaseService.addChatMessage(_userId, botMessage);
      } else {
        await _hiveService.addChatMessage(_userId, userMessage);
        String response = await _geminiService.sendMessage(_userId, _messages, personalityString);
        final botMessage = {"text": response, "isBot": true, 'timestamp': DateTime.now()};
        setState(() {
          _messages.add(botMessage);
        });
        await _hiveService.addChatMessage(_userId, botMessage);
      }
    } catch (e) {
      print("Error sending/saving message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message')),
      );
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