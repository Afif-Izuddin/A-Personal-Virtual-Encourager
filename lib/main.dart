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
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  try {
    await Firebase.initializeApp(); 
  } catch (e) {
    print('Error initializing Firebase in background: $e');
    return; 
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

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
  await Hive.openBox(HiveService.userProfileBox);

   Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, 
  );

  await _initializeNotifications();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

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
        primarySwatch: Colors.blue, 
        scaffoldBackgroundColor: Colors.white, 
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, 
          foregroundColor: Colors.black, 
          elevation: 0, 
        ),

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
  Color _quoteFontColor = Colors.white;
  double _quoteFontSize = 22.0;
  Color _authorFontColor = Colors.white70;
  double _authorFontSize = 16.0;
  double _iconSize = 30.0;
  Set<String> _locallyLikedQuotes = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFontPreferences();
    _loadInitialData();
  }

  Future<void> _loadFontPreferences() async {
    final color = await _firebaseService.getQuoteFontColor();
    final size = await _firebaseService.getQuoteFontSize();
    setState(() {
      _quoteFontColor = color;
      _quoteFontSize = size;
      _authorFontColor = color.withOpacity(0.7);
      _authorFontSize = size - 6;
      _iconSize = size + 8;
    });
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
      
      userTraits = await getTopTraits(_userId); 

      _quotes = await getSkewedQuotes(_userId, userPreferences, userTraits); 
      setState(() {});
    } catch (e) {
      print("Error fetching quotes: $e");
      
    }
  }

  Future<void> _loadSelectedBackground() async {
    final background = await _firebaseService.getSelectedBackground();
    setState(() {
      _selectedBackground = background ?? "assets/background1.jpg";
    });
  }

  void handleLike(String quoteText) {
   setState(() {
    if (_locallyLikedQuotes.contains(quoteText)) {
      _locallyLikedQuotes.remove(quoteText); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quote removed from like')));
    } else {
      _locallyLikedQuotes.add(quoteText); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quote Liked!')));
    }
  });
  
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
                          color: _quoteFontColor,
                          fontSize: _quoteFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '- ${quote['author']}',
                        style: TextStyle(
                          color: _authorFontColor,
                          fontSize: _authorFontSize,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => handleShare(quote['quoteText'], quote['author']),
                            child: Icon(Icons.link, color: _quoteFontColor, size: _iconSize),
                          ),
                          SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => handleSaved(quote['quoteText'], quote['author']),
                            child: Icon(Icons.add, color: _quoteFontColor, size: _iconSize),
                          ),
                          SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => handleLike(quote['quoteText']),
                            child: Icon(
                              _locallyLikedQuotes.contains(quote['quoteText'])
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _quoteFontColor,
                              size: _iconSize,
                            ),
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