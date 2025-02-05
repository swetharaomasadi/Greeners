import 'package:firstly/Login.dart';
import 'package:flutter/material.dart';
import 'search.dart'; // Import the SearchViewScreen here
import 'edit_dues_page.dart';
import 'profit_till_today_page.dart';
import 'settings.dart';
import 'add.dart';
import 'recent_records_page.dart'; // Import the recent records page
import 'firebase_services.dart'; // Import Firebase services for logout
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore to fetch user details

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Function to determine the greeting based on the current time
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Logout function
  void _logout(BuildContext context) async {
    await AuthService().signOut(); // Call the signOut method from Firebase Auth
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoginPage(), // Replace with your login page widget
      ),
    ); // Navigate to login page after logout
  }

  Future<String> getUsernameFromFirestore(String uid) async {
    try {
      // Fetch the user's data from Firestore using UID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users') // Assuming you have a collection 'users'
          .doc(uid) // Fetch the document corresponding to the user's UID
          .get();

      if (snapshot.exists) {
        return snapshot['username'] ??
            'Mr. User'; // Assuming the field is 'username'
      } else {
        return 'Mr. User'; // Return fallback if user is not found
      }
    } catch (e) {
      print('Error fetching username: $e');
      return 'Mr. User'; // Return fallback in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/logo.png', // Add your logo here
              height: 80,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              _logout(context); // Call logout method when pressed
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance
            .authStateChanges(), // Listen for auth state changes
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No user logged in.'));
          }

          final user = snapshot.data;

          return FutureBuilder<String>(
            future: getUsernameFromFirestore(
                user!.uid), // Fetch username from Firestore
            builder: (context, usernameSnapshot) {
              if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (usernameSnapshot.hasError) {
                return Center(child: Text('Error fetching username.'));
              }

              String username = usernameSnapshot.data ??
                  'Mr. User'; // Default fallback username

              return Column(
                children: [
                  SizedBox(height: 40), // Move greeting to top with some space
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Greeting text inside a green box
                        Container(
                          padding: EdgeInsets.all(10),
                          color: Colors.green, // Green background
                          child: Text(
                            getGreeting(), // Dynamic greeting
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // White text color
                            ),
                          ),
                        ),
                        SizedBox(
                            height: 10), // Spacing between greeting and name
                        // Name displayed below the greeting
                        Text(
                          username, // Display fetched username
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(136, 113, 4, 4),
                          ),
                        ),
                        SizedBox(
                            height: 10), // Small spacing between name and icon
                        Icon(Icons.waving_hand, color: Colors.orange, size: 40),
                        SizedBox(height: 15), // Spacing before next section
                        Icon(
                          Icons.mic,
                          size: 70,
                          color: Colors.black,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'AI Voice Assistance',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 51, 238, 9),
                          ),
                        ),
                        SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to the Edit Dues page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditDuesPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 235, 239, 244),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 59, 151, 191)),
                            ),
                          ),
                          child: Text(
                            'Edit Dues',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(251, 179, 112, 10),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to the Profit Till Today page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfitTillTodayPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 235, 239, 244),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 59, 151, 191)),
                            ),
                          ),
                          child: Text(
                            'Profit Till Today',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(250, 13, 3, 97),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {}, // Home action here
              child: Icon(Icons.home, size: 40, color: Colors.blue),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                // Navigate to Search Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchViewScreen(),
                  ),
                );
              },
              child: Icon(Icons.search, size: 40, color: Colors.black),
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                // Navigate to Add Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPage(),
                  ),
                );
              },
              child: Icon(Icons.add, size: 40, color: Colors.black),
            ),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () {
                // Navigate to Recent Records Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecentRecordsPage(),
                  ),
                );
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
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(),
                  ),
                );
              }, // Settings action here
              child: Icon(Icons.settings, size: 40, color: Colors.black),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
