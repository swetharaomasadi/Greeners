import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Auto-generated file
import 'home.dart'; // Home screen
// Login page
import 'signup.dart'; // SignUp page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthCheck(), // Directly set AuthCheck as home page
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // Listen for auth state changes
      builder: (context, snapshot) {
        // While waiting for auth state, show loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // If the user is authenticated, go to HomeScreen
        if (snapshot.hasData) {
          return HomeScreen();
        } else {
          // If the user is not authenticated, go to SignUp or Login page
          return SignUpPage(); // Show SignUpPage by default
        }
      },
    );
  }
}
