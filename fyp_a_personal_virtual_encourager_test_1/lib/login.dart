import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'firstTipi.dart';
import 'firebaseService.dart'; // Import the new service file
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'hive_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  final FirebaseService _firebaseService = FirebaseService(); 

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async { 
    final prefs = await SharedPreferences.getInstance();
    final existingUid = prefs.getString('uid');
    final isGuest = prefs.getBool('isGuest') ?? false;

    if (existingUid != null) {
      if (!isGuest) {
        // Registered user, check Firebase for personality test
        try {
          final hasCompletedTest = await _firebaseService.checkIfPersonalityTestCompleted(existingUid);
          if (hasCompletedTest) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => QuoteScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FirstPersonalityTestScreen()),
            );
          }
        } catch (e) {
          print('Error checking user status: $e');
          // Handle the error appropriately, maybe show a snackbar
        }
      } else {
        final personalityBox = HiveService.getPersonalityTestResultsBox();
        if (personalityBox.containsKey(existingUid)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => QuoteScreen()),
          );
      } else {
        // Guest user
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FirstPersonalityTestScreen()),
        );
        }
      }
    }
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final guestUid = Uuid().v4();
    await prefs.setString('uid', guestUid);
    await prefs.setBool('isGuest', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => FirstPersonalityTestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Welcome back!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter Your Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: 'Enter Your Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userCredential = await _firebaseService.signInWithEmailAndPassword(
                      _emailController.text,
                      _passwordController.text,
                    );
                    print('Logged in as: ${userCredential.user!.email}');
                    await _firebaseService.saveUserId(userCredential.user!.uid);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => QuoteScreen()),
                    );
                  } on FirebaseAuthException catch (e) {
                    String errorMessage;
                    if (e.code == 'user-not-found') {
                      errorMessage = 'No user found for that email.';
                    } else if (e.code == 'wrong-password') {
                      errorMessage = 'Wrong password provided for that user.';
                    } else if (e.code == 'invalid-email') {
                      errorMessage = 'Invalid email format.';
                    } else if (e.code == 'too-many-requests') {
                      errorMessage = 'Too many requests. Try again later.';
                    } else {
                      errorMessage = 'An error occurred during login.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                    print(e.code);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Login', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 16),
              ElevatedButton( // Add the "Continue as Guest" button here
                onPressed: _continueAsGuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Continue as Guest', style: TextStyle(fontSize: 16)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupScreen()),
                      );
                    },
                    child: Text('Signup'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscureText = true;
  final FirebaseService _firebaseService = FirebaseService(); // Instantiate the service

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Signup',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Enter Your Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter Your Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: 'Enter Your Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userCredential = await _firebaseService.createUserWithEmailAndPassword(
                      _emailController.text,
                      _passwordController.text,
                    );
                    await _firebaseService.createUserDocument(userCredential.user!, _usernameController.text);
                    await _firebaseService.saveUserId(userCredential.user!.uid);

                    print('Signed up user: ${userCredential.user!.email}');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => FirstPersonalityTestScreen()),
                    );
                  } on FirebaseAuthException catch (e) {
                    String errorMessage;
                    if (e.code == 'weak-password') {
                      errorMessage = 'The password provided is too weak.';
                    } else if (e.code == 'email-already-in-use') {
                      errorMessage = 'The account already exists for that email.';
                    } else if (e.code == 'invalid-email') {
                      errorMessage = 'The email address is badly formatted.';
                    } else if (e.code == 'too-many-requests') {
                      errorMessage = 'Too many requests try again later.';
                    } else {
                      errorMessage = 'An error occurred during signup.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                    print(e.code);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating user data.')));
                    print(e);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Signup', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}