import 'package:flutter/material.dart';
import 'home.dart'; // Import the home.dart file where your HomeScreen is defined

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // This is the initial screen that will load when the app starts
    );
  }
}
