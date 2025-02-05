import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Login.dart'; // Login page

class AuthGuard extends StatelessWidget {
  final Widget child;  // The page that is wrapped by the AuthGuard

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Stream to listen to auth state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is active and the user is not authenticated
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return child;  // If user is authenticated, show the requested page
          } else {
            // If the user is not authenticated, redirect to login
            return LoginPage();
          }
        }
        // If the connection is not active (still loading), show a loading spinner
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
