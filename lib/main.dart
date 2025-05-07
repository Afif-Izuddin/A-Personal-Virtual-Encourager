import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'settingScreen.dart';
import 'profileSetting.dart';
import 'login.dart';
import 'chat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quotesort.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class Quote {
  final String id;
  final String text;
  final String author;

  Quote({required this.id, required this.text, required this.author});

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
class QuoteScreen extends StatefulWidget { 
  @override
  _QuoteScreenState createState() => _QuoteScreenState();
}
class _QuoteScreenState extends State<QuoteScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _quotes = [];
  String _selectedBackground = "assets/background1.jpg";
  List<String> userPreferences = []; 
  List<String> userTraits = [];

  @override
  void initState() {
    super.initState;
    loadUserID();
    _loadSelectedBackground();
  }

  String _userId = " ";

  Future<void> loadUserID() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _userId = prefs.getString('uid') ?? ""; 
  });
  _fetchQuotes();
  print(_userId);
  }
  

  Future<void> _fetchQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    if (uid == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }

    try {
      final userDoc = await firestore.collection('user').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userPreferences = List<String>.from(userData['preference'] ?? []);
        userTraits = await getTopTraits(uid); 

        _quotes = await getSkewedQuotes(uid, userPreferences, userTraits);
        setState(() {}); 
      } else {
        print("User document not found.");
      }
    } catch (e) {
      print("Error fetching quotes: $e");
    }
  }

  Future<void> _loadSelectedBackground() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _selectedBackground = prefs.getString('selectedBackground') ?? "assets/background1.jpg"; 
  });
}


  void handleLike(String quoteId) {
  }
  
  void handleSaved(String quoteText, String author) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    await firestore.collection('savedQuote').add({
      'userID': _userId,
      'quoteText': quoteText,
      'author': author,
    });
    print('Quote saved successfully!');
  } catch (e) {
    print('Error saving quote: $e');
  }
}

  void handleShare(String quoteText, String author) {
    String message = '"$quoteText" - $author'; 
    Share.share(message);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(_selectedBackground), 
              fit: BoxFit.cover, 
            ),
          ),
        ),
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _quotes.length,
            itemBuilder: (context, index) {
              final quote = _quotes[index];
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quote['quoteText'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '- ${quote['author']}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => handleShare(quote['quoteText'], quote['author']),
                            child: Icon(Icons.link, color: Colors.white, size: 30),
                          ),
                          SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => handleSaved(quote['quoteText'], quote['author']),
                            child: Icon(Icons.add, color: Colors.white, size: 30),
                          ),
                          SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => handleLike(quote['id']),
                            child: Icon(Icons.favorite_border, color: Colors.white, size: 30),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Positioned(
            top: 35,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
              child: _buildButtonBase(icon: Icons.settings),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              child: _buildButtonBase(icon: Icons.chat_bubble_outline),
            ),
            
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilesettingScreen()),
                );
              },
              child: _buildButtonBase(icon: Icons.person_outline),
            ),
            
          ),
        ],
      ),
    );
  }

  Widget _buildButtonBase({required IconData icon}) {
    return Container(
      padding: EdgeInsets.all(10), 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(10), 
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}


