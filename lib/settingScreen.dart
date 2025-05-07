import 'package:flutter/material.dart';
import 'changeBackground.dart';

class SettingsScreen extends StatelessWidget {
  final List<Map<String, String>> settingsOptions = [
    {"id": "1", "title": "Background", "subtitle": "Change your background for the daily quotes here"},
    {"id": "2", "title": "Reminder", "subtitle": "Set and get your notification with encouragement"},
    {"id": "3", "title": "Widgets", "subtitle": "Adjust or add widgets to your home screen"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: settingsOptions.map((option) {
            return _buildSettingsItem(option["title"]!, option["subtitle"]!, context);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, String subtitle, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == "Background") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => BackgroundScreen()));
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
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
              width: 50, 
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.lightBlueAccent, 
              ),
              child: Icon(
                Icons.image_outlined, 
                color: Colors.white,
                size: 24, 
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
              icon: Icon(Icons.arrow_forward_ios, color: Colors.black), 
              onPressed: () {
                if (title == "Background") {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BackgroundScreen()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}