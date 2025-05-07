import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  
  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> _userPreferences = [];
  bool _isLoading = true;

  String _userId = " ";

  Future<void> loadUserID() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _userId = prefs.getString('uid') ?? "assets/background1.jpg"; 
  });
  _fetchUserPreferences();
  }



  final List<String> allPreferences = [
    "Life",
    "School",
    "Work",
    "Love",
    "Friendship",
    "Health and Fitness",
    "Success",
    "Failure",
    "Perseverance",
    "Courage",
    "Creativity",
    "Change and Growth",
    "Self-Confidence",
    "Happiness",
    "Dreams and Goals",
    "Leadership",
    "Mindfulness",
    "Time Management",
    "Overcoming Obstacles",
    "Gratitude"
];

  @override
  void initState() {
    super.initState();
    loadUserID();
    
  }

  Future<void> _fetchUserPreferences() async {
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('user').doc(_userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userPreferences = List<String>.from(userData['preference'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching preferences: $e");
       setState(() {
          _isLoading = false;
        });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching preferences')),
      );
    }
  }

  Future<void> _updateUserPreferences(String preference) async {
    try {
      List<String> updatedPreferences = List.from(_userPreferences);

      if (updatedPreferences.contains(preference)) {
        updatedPreferences.remove(preference);
      } else {
        updatedPreferences.add(preference);
      }

      await firestore.collection('user').doc(_userId).update({
        'preference': updatedPreferences,
      });

      setState(() {
        _userPreferences = updatedPreferences;
      });
    } catch (e) {
      print("Error updating preferences: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating preferences')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        iconTheme: IconThemeData(color: Colors.black), 
        title: Text("Preferences", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0, 
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: allPreferences.map((preference) {
                  bool isSelected = _userPreferences.contains(preference);
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      onTap: () => _updateUserPreferences(preference),
                      title: Text(preference, style: TextStyle(color: Colors.black)), 
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.circle_outlined, color: Colors.black), 
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}