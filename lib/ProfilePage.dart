import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  ProfilePage({super.key}); // Get the logged-in user

  // Fetch user info from Firestore
  Future<Map<String, String>> getUserInfo() async {
    if (user != null) {
      // Fetch username from Firestore based on UID
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid) // Use user.uid
            .get();

        if (userDoc.exists) {
          String username = userDoc.get('username') ?? 'Username not set';
          String email = user?.email ?? 'Email not available';

          return {
            'username': username,
            'email': email,
          };
        } else {
          return {
            'username': 'No user found in Firestore',
            'email': 'No email available',
          };
        }
      } catch (e) {
        print('Error fetching user info: $e');
        return {
          'username': 'Error fetching username',
          'email': 'Error fetching email',
        };
      }
    }
    return {
      'username': 'No user logged in',
      'email': 'No email available',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Light background color
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue, // Blue background for the AppBar
      ),
      body: FutureBuilder<Map<String, String>>(
        future: getUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error fetching user data'));
          }

          final userInfo = snapshot.data ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Picture Section
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // User Info Container
                Card(
                  elevation: 5,
                  shadowColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Username: ${userInfo['username']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Email: ${userInfo['email']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Log Out Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: Icon(Icons.exit_to_app),
                  label: Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
