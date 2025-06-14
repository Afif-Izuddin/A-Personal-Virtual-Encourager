// test/mocks/mock_dependencies.dart
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:fyp_a_personal_virtual_encourager_test_1/firebaseService.dart'; // Adjust path
import 'package:fyp_a_personal_virtual_encourager_test_1/hive_service.dart';     // Adjust path

// Generates mocks for the services and core Flutter/Firebase/Hive classes
@GenerateMocks([
  FirebaseService,
  HiveService,
  SharedPreferences,
  FirebaseAuth, // Mock FirebaseAuth for internal calls in FirebaseService
  UserCredential, // To simulate successful login result
  User, // To simulate a logged-in user
  Box, // To mock Hive box operations
], customMocks: [
  // REMOVE 'returnNullOnMissingStub: true' from all MockSpec lines
  MockSpec<SharedPreferences>(as: #MockSharedPreferences),
  MockSpec<UserCredential>(as: #MockUserCredential),
  MockSpec<User>(as: #MockUser),
  MockSpec<Box>(as: #MockBox),
])
void main() {} // Empty main for build_runner