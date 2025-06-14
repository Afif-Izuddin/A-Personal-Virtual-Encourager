import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'firebaseService.dart';
import 'hive_service.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _dobController;
  String? _selectedBelief;
  String? _selectedGender;
  final FirebaseService _firebaseService = FirebaseService();
  final HiveService _hiveService = HiveService();
  bool _isLoading = true;
  String _currentUsername = '';
  String _currentDob = '';
  String? _currentBelief;
  String? _currentGender;
  String _userId = "";
  bool _isGuest = false;

  final List<String> _commonBeliefs = [
    'Agnostic',
    'Atheist',
    'Buddhist',
    'Christian',
    'Hindu',
    'Jewish',
    'Muslim',
    'Spiritual but not religious',
    'Other',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: '');
    _dobController = TextEditingController(text: '');
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    await _loadUserId();
    if (_userId.isNotEmpty) {
      _isGuest = await _firebaseService.getGuestStatus();
      if (!_isGuest) {
        await _fetchFirebaseUserData();
      } else {
        await _fetchHiveUserData();
      }
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

  Future<void> _fetchFirebaseUserData() async {
    if (_userId.isEmpty) return;
    try {
      final userData = await _firebaseService.getUserProfile(_userId);
      setState(() {
        _currentUsername = userData['username'] ?? '';
        _currentDob = userData['dob'] ?? '';
        _currentBelief = userData['belief'];
        _currentGender = userData['gender'];
        _usernameController.text = _currentUsername;
        _dobController.text = _currentDob;
        _selectedBelief = _currentBelief;
        _selectedGender = _currentGender;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching user data from Firebase: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data')),
      );
    }
  }

  Future<void> _fetchHiveUserData() async {
    final profileData = _hiveService.getUserProfile(_userId);
    setState(() {
      _currentUsername = profileData?['username'] ?? '';
      _currentDob = profileData?['dob'] ?? '';
      _currentBelief = profileData?['belief'];
      _currentGender = profileData?['gender'];
      _usernameController.text = _currentUsername;
      _dobController.text = _currentDob;
      _selectedBelief = _currentBelief;
      _selectedGender = _currentGender;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDob.isNotEmpty ? DateTime.parse(_currentDob) : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });
    final profileData = {
      'username': _usernameController.text,
      'gender': _selectedGender,
      'dob': _dobController.text,
      'belief': _selectedBelief,
    };
    try {
      if (!_isGuest) {
        await _firebaseService.updateUserProfile(
          _userId,
          _usernameController.text,
          _selectedGender,
          _dobController.text,
          _selectedBelief,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      } else {
        await _hiveService.saveUserProfile(_userId, profileData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated locally (Guest)!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error updating profile: $e");
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
            : SingleChildScrollView(
                child: Column(
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
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: _dobController,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedGender,
                      items: <String>['Male', 'Female', 'Other', 'Prefer not to say']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Beliefs',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedBelief,
                      items: _commonBeliefs.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBelief = newValue;
                        });
                      },
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
      ),
    );
  }
}