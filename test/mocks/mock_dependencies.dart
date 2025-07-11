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
  FirebaseAuth, // This remains here as it's not given a custom 'MockFirebaseAuth' alias
  // REMOVED Box from here (now only in customMocks)
], customMocks: [
  MockSpec<SharedPreferences>(as: #MockSharedPreferences),
  MockSpec<UserCredential>(as: #MockUserCredential),
  MockSpec<User>(as: #MockUser),
  MockSpec<Box>(as: #MockBox), // Keep this here
])
void main() {} // Empty main for build_runner