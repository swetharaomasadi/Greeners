import 'package:flutter/material.dart';
import 'firebase_services.dart'; // Import the firebase services
import 'Signup.dart'; // Import the sign-up page
import 'home.dart'; // Import your HomePage widget
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String _errorMessage = '';

  // Login method that checks email, username, or phone number
  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String username = email; // Treat email as username if no email
    String phone = email; // Treat email as phone number if no phone number

    if (email.isNotEmpty || username.isNotEmpty || phone.isNotEmpty) {
      dynamic user;

      // First try logging in with email and password
      if (email.isNotEmpty) {
        user = await _authService.login(email, password);
      }

      // If login by email fails, check Firestore for a matching username or phone number
      user ??= await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get()
          .then((value) =>
              value.docs.isNotEmpty ? value.docs.first.data() : null);

      user ??= await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get()
          .then((value) =>
              value.docs.isNotEmpty ? value.docs.first.data() : null);

      if (user != null) {
        // If a matching user is found, save session and navigate to HomeScreen
        await _authService.saveSession(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = "Login failed. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', height: 150),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email / Username / Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpPage()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
