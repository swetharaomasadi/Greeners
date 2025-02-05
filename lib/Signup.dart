import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_services.dart'; // Import the firebase services
import 'home.dart'; // Import HomePage widget
import 'Login.dart'; // Import LoginPage widget

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String _errorMessage = '';

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signUp() async {
    String username = _usernameController.text;
    String email = _emailController.text;
    String phone = _phoneController.text;
    String password = _passwordController.text;

    if (email.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        phone.isEmpty) {
      setState(() {
        _errorMessage = "Please fill all fields.";
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = "Please enter a valid email address.";
      });
      return;
    }

    // Check if the username already exists
    var usernameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      setState(() {
        _errorMessage = "Username is already taken. Please choose another.";
      });
      return;
    }

    // Check if the phone number already exists
    var phoneQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();

    if (phoneQuery.docs.isNotEmpty) {
      setState(() {
        _errorMessage = "Phone number is already registered.";
      });
      return;
    }

    // Check if the email is already registered in Firebase Auth
    var authResult =
        await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    if (authResult.isNotEmpty) {
      setState(() {
        _errorMessage =
            "Email is already registered. Please use a different one.";
      });
      return;
    }

    // If all checks pass, create the user with email and password
    var user = await _authService.signUp(email, password);
    if (user != null) {
      // Store user info in Firestore
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
        'email': email,
        'phone': phone,
      }).then((value) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeScreen()), // Navigate to HomePage widget
        );
      }).catchError((error) {
        setState(() {
          _errorMessage = "Error saving user info: $error";
        });
      });
    } else {
      setState(() {
        _errorMessage = "Sign up failed. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adjust the width based on screen size
                double maxWidth =
                    constraints.maxWidth > 600 ? 600 : constraints.maxWidth;

                return SizedBox(
                  width: maxWidth, // Set the width to be responsive
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', height: 150),
                      SizedBox(height: 30),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                        ),
                        child: Text('Sign Up', style: TextStyle(fontSize: 18)),
                      ),
                      SizedBox(height: 15),
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        LoginPage()), // Navigate to LoginPage widget
                              );
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
