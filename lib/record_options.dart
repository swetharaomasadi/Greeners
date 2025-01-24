import 'package:firstly/add.dart';
import 'package:flutter/material.dart';
import 'package:firstly/profit_record.dart'; // Import your profit_record.dart
import 'package:firstly/expenditures_record.dart'; // Import your expenditures_record.dart
import 'package:firstly/home.dart'; // Import your Home Screen (if you have one)
import 'package:firstly/search.dart'; // Import the Search Screen
import 'package:firstly/settings.dart'; // Import your Settings Screen

class RecordOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black), // Back arrow
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/logo.png', // Replace with your logo asset path
              height: 80,
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[200], // Light gray background
        child: Center( // Center content vertically and horizontally
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              // Option 1: To Create Vendor's Record
              GestureDetector(
                onTap: () {
                  // Navigate to Vendor's Record (Profit Record)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfitRecord()), // Navigate to profit_record.dart
                  );
                },
                child: Column(
                  children: [
                    Icon(Icons.note_add, size: 80, color: Colors.black),
                    SizedBox(height: 10),
                    Text(
                      "Add Profits",
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40), // Space between the options
              // Option 2: To Create Expenditures Record
              GestureDetector(
                onTap: () {
                  // Navigate to Expenditures Record
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExpendituresRecord()), // Navigate to expenditures_record.dart
                  );
                },
                child: Column(
                  children: [
                    Icon(Icons.receipt, size: 80, color: Colors.black),
                    SizedBox(height: 10),
                    Text(
                      "Add Expenditures",
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: Icon(Icons.home, size: 40, color: Colors.black),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchViewScreen()),
                );
              },
              child: Icon(Icons.search, size: 40, color: Colors.black),
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                // Navigate to Add Page (or the page you need)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPage()),
                );
              },
              child: Icon(Icons.add, size: 40, color: Colors.blue),
            ),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                // Recent action here
              },
              child: Icon(Icons.history, size: 40, color: Colors.black),
            ),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
              child: Icon(Icons.settings, size: 40, color: Colors.black),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
