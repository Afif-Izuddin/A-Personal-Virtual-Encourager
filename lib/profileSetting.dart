import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'saved.dart';
import 'preference.dart';
import 'editProfile.dart';
import 'tipi.dart';
import 'login.dart';

class ProfilesettingScreen extends StatelessWidget {
  final List<Map<String, String>> settingsOptions = [
    {"id": "1", "title": "Edit Profile", "subtitle": "Edit you profile information here"},
    {"id": "2", "title": "Retake TIPI Test", "subtitle": "Retake your personality test when you feel the need to"},
    {"id": "3", "title": "Preferences", "subtitle": "Change your preferences regarding the content you see"},
    {"id": "4", "title": "Saved", "subtitle": "Manage and see saved quotes"},
  ];

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
        title: Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            ...settingsOptions.map((option) {
              return _buildSettingsItem(option["title"]!, option["subtitle"]!, context);
            }),
            SizedBox(height: 20),
            _buildSignOutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, String subtitle, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == "Saved") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SavedQuotesScreen()));
        } else if (title == "Preferences") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PreferencesScreen()));
        } else if (title == "Edit Profile") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
        } else if (title == "Retake TIPI Test") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalityTestScreen()));
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
              onPressed: () {
                if (title == "Saved") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SavedQuotesScreen()));
                } else if (title == "Preferences") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PreferencesScreen()));
                } else if (title == "Edit Profile") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
                } else if (title == "Retake TIPI Test") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalityTestScreen()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('uid');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      },
      child: Text('Sign Out'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}