import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedQuotesScreen extends StatefulWidget {
  @override
  _SavedQuotesScreenState createState() => _SavedQuotesScreenState();
}

class _SavedQuotesScreenState extends State<SavedQuotesScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String _userId = " ";

  Future<void> loadUserID() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _userId = prefs.getString('uid') ?? "assets/background1.jpg"; 
  });
  _fetchSavedQuotes();
  print(_userId);
  }
  
  List<Quote> _savedQuotes = []; 

  @override
  void initState() {
    super.initState();
    loadUserID();
    print("runs");
  }
  
  Future<void> _deleteQuote(String quoteId) async { 
    try {
      await firestore.collection('savedQuote').doc(quoteId).delete();

      setState(() {
        _savedQuotes.removeWhere((quote) => quote.id == quoteId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote deleted!')),
      );
    } catch (e) {
      print("Error deleting quote: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting quote')),
      );
    }
  }


  Future<void> _fetchSavedQuotes() async {
    try {
      final snapshot = await firestore
          .collection('savedQuote')
          .where('userID', isEqualTo: _userId)
          .get();

      setState(() {
        _savedQuotes = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Quote(
            id: doc.id,
            text: data['quoteText'] as String,
            author: data['author'] as String,
          );
        }).toList();
      });
      print(_savedQuotes);
    } catch (e) {
      print("Error fetching saved quotes: $e");
      
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
                final quoteData = _savedQuotes[index];
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
                                quoteData.text,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "- ${quoteData.author}",
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
                                '${quoteData.text} - ${quoteData.author}',
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteQuote(quoteData.id);;
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