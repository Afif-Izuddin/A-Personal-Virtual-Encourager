import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'main.dart';
import 'firebaseService.dart'; 
import 'hive_service.dart'; 

class SavedQuotesScreen extends StatefulWidget {
  @override
  _SavedQuotesScreenState createState() => _SavedQuotesScreenState();
}

class _SavedQuotesScreenState extends State<SavedQuotesScreen> {
  final FirebaseService _firebaseService = FirebaseService(); 
  final HiveService _hiveService = HiveService(); 
  String _userId = "";
  bool _isGuest = false;
  List<Quote> _savedQuotes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    await _loadUserStatus();
    await _loadUserId();
    if (_userId.isNotEmpty) {
      if (!_isGuest) {
        await _fetchSavedQuotesFromFirebase();
      } else {
        await _fetchSavedQuotesFromHive();
      }
    }
    print("runs");
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
    print(_userId);
  }

  Future<void> _fetchSavedQuotesFromFirebase() async {
    try {
      final savedQuotes = await _firebaseService.fetchSavedQuotes(_userId);
      setState(() {
        _savedQuotes = savedQuotes;
      });
      print(_savedQuotes);
    } catch (e) {
      print("Error fetching saved quotes from Firebase in UI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved quotes')),
      );
    }
  }

  Future<void> _fetchSavedQuotesFromHive() async {
    try {
      final savedQuotesMapList = await _hiveService.getSavedQuotes(_userId);
      setState(() {
        _savedQuotes = savedQuotesMapList?.map((map) => Quote(
              id: '${_userId}_${map['quoteText'].hashCode}_${map['author'].hashCode}', 
              text: map['quoteText']!,
              author: map['author']!,
            )).toList() ?? [];
      });
      print("Saved quotes from Hive: $_savedQuotes");
    } catch (e) {
      print("Error fetching saved quotes from Hive in UI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved quotes')),
      );
    }
  }

  Future<void> _deleteQuote(Quote quote) async {
    try {
      if (!_isGuest) {
        await _firebaseService.deleteSavedQuote(quote.id);
        setState(() {
          _savedQuotes.removeWhere((q) => q.id == quote.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quote deleted!')),
        );
      } else {
        await _hiveService.deleteSavedQuote(_userId, quote.text, quote.author);
        setState(() {
          _savedQuotes.removeWhere((q) => q.text == quote.text && q.author == quote.author);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quote deleted locally!')),
        );
      }
    } catch (e) {
      print("Error deleting quote in UI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting quote')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("Saved", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: _savedQuotes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        "There is nothing here yet! Start saving your favourite quotes and see them here!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _savedQuotes.length,
                itemBuilder: (context, index) {
                  final quote = _savedQuotes[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quote.text,
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "- ${quote.author}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.share, color: Colors.blue),
                                onPressed: () => Share.share(
                                  '${quote.text} - ${quote.author}',
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteQuote(quote);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}