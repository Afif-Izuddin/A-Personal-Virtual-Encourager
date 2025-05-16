import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'settingScreen.dart';
import 'profileSetting.dart';
import 'login.dart';
import 'chat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'quotesort.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebaseService.dart'; 
import 'hive_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:home_widget/home_widget.dart';

@pragma('vm:entry-point')
void callbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  try {
    await Firebase.initializeApp(); // Initialize Firebase
  } catch (e) {
    print('Error initializing Firebase in background: $e');
    return; // Exit if Firebase initialization fails
  }

  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'fetchDailyQuoteAndUpdateWidget':
        try {
          print('Workmanager task "fetchDailyQuoteAndUpdateWidget" executed.');

          final FirebaseService firebaseService = FirebaseService();
          final Quote? randomQuote = await firebaseService.fetchRandomQuote();

          if (randomQuote != null) {
            await HomeWidget.saveWidgetData<String>('QUOTE_KEY', randomQuote.text);
            await HomeWidget.saveWidgetData<String>('AUTHOR_KEY', randomQuote.author);
            await HomeWidget.updateWidget(name: 'DailyQuoteWidgetProvider');
            print('Quote saved and widget update triggered: "${randomQuote.text}" - ${randomQuote.author}');
            return Future.value(true);
          } else {
            print('Error: Failed to fetch a random quote.');
            return Future.value(false);
          }
        } catch (e) {
          print('Error during background quote update: $e');
          return Future.value(false);
        }
      default:
        return Future.value(true);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await Hive.openBox(HiveService.appSettingsBox); 
  await Hive.openBox(HiveService.personalityTestResultsBox);
  await Hive.openBox(HiveService.userPreferencesBox);
  await Hive.openBox(HiveService.savedQuoteBox);
  await Hive.openBox(HiveService.chatMessagesBox);
  await Hive.openBox(HiveService.alarmsBox);

   Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, 
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
      title: 'Personal Virtual Encourager',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set the primary color to blue
        scaffoldBackgroundColor: Colors.white, // Set the background color of Scaffolds to white
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // Ensure AppBar background is also white
          foregroundColor: Colors.black, // Set AppBar text and icon color to black
          elevation: 0, // Remove AppBar shadow if desired
        ),
        // You can customize other theme properties here as well,
        // like text styles, button themes, etc.
      ),
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
  final FirebaseService _firebaseService = FirebaseService(); 
  final HiveService _hiveService = HiveService();
  List<Map<String, dynamic>> _quotes = [];
  String _selectedBackground = "assets/background1.jpg";
  List<String> userPreferences = [];
  List<String> userTraits = [];
  String _userId = "";
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserStatus();
    await _loadUserId();
    await _loadSelectedBackground();
    if (_userId.isNotEmpty) {
      await _fetchQuotes();
    }
  }

  Future<void> _loadUserStatus() async {
    final isGuestStatus = await _firebaseService.getGuestStatus();
    setState(() {
      _isGuest = isGuestStatus;
    });
  }

  Future<void> _loadUserId() async {
    final userId = await _firebaseService.getCurrentUserId();
    setState(() {
      _userId = userId ?? "";
    });
    print('User ID: $_userId');
  }

  Future<void> _fetchQuotes() async {
    if (_userId.isEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }

    try {
      if(!_isGuest){
        userPreferences = await _firebaseService.getUserPreferences(_userId);
      } else {
        userPreferences = await _hiveService.getUserPreferences(_userId) ?? [];
      }
      
      userTraits = await getTopTraits(_userId); // Assuming getTopTraits is in quotesort.dart

      _quotes = await getSkewedQuotes(_userId, userPreferences, userTraits); // Assuming getSkewedQuotes is in quotesort.dart
      setState(() {});
    } catch (e) {
      print("Error fetching quotes: $e");
      // Handle error appropriately
    }
  }

  Future<void> _loadSelectedBackground() async {
    final background = await _firebaseService.getSelectedBackground();
    setState(() {
      _selectedBackground = background ?? "assets/background1.jpg";
    });
  }

  void handleLike(String quoteId) {
    // Implement like functionality (may involve Firebase in the future)
  }

  void handleSaved(String quoteText, String author) async {
    try {
      if (_isGuest) {
        await _hiveService.saveQuote(_userId, quoteText, author);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quote saved locally!')));
      } else {
        await _firebaseService.saveQuote(_userId, quoteText, author);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quote saved!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save quote.')));
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