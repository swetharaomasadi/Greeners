import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving session locally

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to sign up a new user
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
    
      return null;
    }
  }

  // Method to log in a user using username, email, or phone
  Future<User?> login(String usernameOrEmailOrPhone, String password) async {
    try {
      // First, try to find the user by username, email, or phone in Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: usernameOrEmailOrPhone)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: usernameOrEmailOrPhone)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: usernameOrEmailOrPhone)
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        var userDoc = snapshot.docs[0];
        String email = userDoc['email'];
        // Sign in with the found email and password
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Save session after successful login
        await saveSession(userCredential.user);

        return userCredential.user;
      }
      return null;
    } catch (e) {
   
      return null;
    }
  }

  // Method to log out and clear the session
  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear saved session data
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Save user session (e.g., user details or token) locally using SharedPreferences
  Future<void> saveSession(User? user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (user != null) {
        // Store user information in local storage
        await prefs.setString('userEmail', user.email ?? ''); // Save user email
        await prefs.setString('userUid', user.uid); // Save user UID
        // You can add more user data as needed
      }
    } catch (e) {
      print("Error saving session: $e");
    }
  }

  // Method to get saved session data
  Future<Map<String, String?>> getSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    String? uid = prefs.getString('userUid');

    return {'email': email, 'uid': uid};
  }
}
