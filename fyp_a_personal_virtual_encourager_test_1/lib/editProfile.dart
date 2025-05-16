import 'package:flutter/material.dart';
import 'firebaseService.dart'; // Import FirebaseService

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  final FirebaseService _firebaseService = FirebaseService(); // Instantiate FirebaseService
  bool _isLoading = true;
  String _currentUsername = '';
  String _userId = "";

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: '');
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    await _loadUserId();
    if (_userId.isNotEmpty) {
      await _fetchUserData();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found')),
      );
    }
  }

  Future<void> _loadUserId() async {
    final userId = await _firebaseService.getCurrentUserId();
    setState(() {
      _userId = userId ?? "";
    });
    print(_userId);
  }

  Future<void> _fetchUserData() async {
    if (_userId.isEmpty) return;
    try {
      final username = await _firebaseService.getUsername(_userId);
      setState(() {
        _currentUsername = username ?? '';
        _usernameController.text = _currentUsername;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching user data in UI: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _firebaseService.updateUsername(_userId, _usernameController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error updating profile in UI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
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
        title: Text("Edit Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Update', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
      ),
    );
  }
}