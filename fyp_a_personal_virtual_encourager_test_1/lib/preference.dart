import 'package:flutter/material.dart';
import 'firebaseService.dart'; // Import FirebaseService
import 'hive_service.dart'; // Import HiveService

class PreferencesScreen extends StatefulWidget {
  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final FirebaseService _firebaseService = FirebaseService(); // Instantiate FirebaseService
  final HiveService _hiveService = HiveService(); // Instantiate HiveService
  List<String> _userPreferences = [];
  bool _isLoading = true;
  String _userId = "";
  bool _isGuest = false;

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
    _loadPreferencesData();
  }

  Future<void> _loadPreferencesData() async {
    await _loadUserStatus();
    if (_userId.isNotEmpty) {
      if (!_isGuest) {
        await _fetchUserPreferencesFromFirebase();
      } else {
        await _fetchUserPreferencesFromHive();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserStatus() async {
    final userId = await _firebaseService.getCurrentUserId();
    final isGuestStatus = await _firebaseService.getGuestStatus();
    setState(() {
      _userId = userId ?? "";
      _isGuest = isGuestStatus;
    });
  }

  Future<void> _fetchUserPreferencesFromFirebase() async {
    try {
      final preferences = await _firebaseService.getUserPreferenceList(_userId);
      setState(() {
        _userPreferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching preferences from Firebase in UI: $e");
      _handleFetchError();
    }
  }

  Future<void> _fetchUserPreferencesFromHive() async {
    try {
      final preferences = await _hiveService.getUserPreferences(_userId);
      setState(() {
        _userPreferences = preferences ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching preferences from Hive in UI: $e");
      _handleFetchError();
    }
  }

  void _handleFetchError() {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching preferences')),
    );
  }

  Future<void> _updateUserPreferences(String preference) async {
    List<String> updatedPreferences = List.from(_userPreferences);

    if (updatedPreferences.contains(preference)) {
      updatedPreferences.remove(preference);
    } else {
      updatedPreferences.add(preference);
    }

    if (!_isGuest) {
      await _updateUserPreferencesInFirebase(updatedPreferences);
    } else {
      await _updateUserPreferencesInHive(updatedPreferences);
    }

    setState(() {
      _userPreferences = updatedPreferences;
    });
  }

  Future<void> _updateUserPreferencesInFirebase(List<String> preferences) async {
    try {
      await _firebaseService.updateUserPreferences(_userId, preferences);
    } catch (e) {
      print("Error updating preferences in Firebase UI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating preferences online')),
      );
    }
  }

  Future<void> _updateUserPreferencesInHive(List<String> preferences) async {
    try {
      await _hiveService.saveUserPreferences(_userId, preferences);
    } catch (e) {
      print("Error updating preferences in Hive UI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating preferences locally')),
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