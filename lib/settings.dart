import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Delete_records.dart';

import 'ProfilePage.dart';
import 'Login.dart';
import 'home.dart';
import 'search.dart';
import 'add.dart';
import 'recent_records_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SettingsPage());
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 4; // Initially, we're on the Settings page

  // This function will handle the navigation logic based on the selected index.
  void _onItemTapped(int index) {
  if (index == _selectedIndex) return; // Prevent reloading the same page

  switch (index) {
    case 0:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()), // Navigate to Home
      );
      break;
    case 1:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SearchScreen()), // Navigate to Search
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AddPage()), // Navigate to Add
      );
      break;
    case 3:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RecentRecordsPage()), // Navigate to Recent
      );
      break;
    case 4:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage()), // Stay on Settings Page
      );
      break;
  }
}


  // Show dialog to update user name
  void _changeUserName() async {
    TextEditingController userNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change User Name'),
          content: TextField(
            controller: userNameController,
            decoration: const InputDecoration(labelText: 'New User Name'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                String newUserName = userNameController.text;

                // Update the display name in Firebase Authentication
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.updateDisplayName(newUserName);
                  // Optionally update the name in Firestore as well
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'username': newUserName});

                  print('User Name changed to: $newUserName');
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to update password
  void _changePassword() async {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                String newPassword = passwordController.text;

                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.updatePassword(newPassword);
                  print('Password changed');
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _changePhoneNumber() async {
    TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Phone Number'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'New Phone Number'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newPhoneNumber = phoneController.text.trim();
                Navigator.pop(context); // Close the dialog

                if (newPhoneNumber.isEmpty) {
                  print("Phone number cannot be empty.");
                  return;
                }

                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    // Update phone number in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'phone': newPhoneNumber});

                    print(
                        'Phone Number updated successfully to: $newPhoneNumber');
                  } catch (e) {
                    print("Error updating phone number: $e");
                  }
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

void _deleteAccount() async {
  // Show dialog to enter the password for verification
  TextEditingController passwordController = TextEditingController();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your password to confirm account deletion.'),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog

              // Get the entered password
              String password = passwordController.text.trim();

              if (password.isEmpty) {
                // Show an error if the password is empty
                _showErrorDialog('Please enter a password.');
                return;
              }

              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  // Re-authenticate the user with the provided password
                  AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!, password: password);

                  await user.reauthenticateWithCredential(credential);

                  // If the re-authentication is successful, delete the account
                  await _deleteUserAccount(user);
                } catch (e) {
                  // If authentication fails, show an error message
                  _showErrorDialog('Incorrect password. Please try again.');
                }
              }
            },
            child: const Text('Confirm'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

// Method to show error dialog
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the error dialog
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

// Method to delete the user's account and data
Future<void> _deleteUserAccount(User user) async {
  try {
    // Delete user data from Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .delete();

    // Delete the user's expenditures from Firestore
    await FirebaseFirestore.instance
        .collection('expenditures')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.delete();
      }
    });

    // Delete the user from Firebase Authentication
    await user.delete();

    // Sign out the user
    await FirebaseAuth.instance.signOut();

    // Immediately navigate to the Login page without requiring a refresh
    if (mounted) {
      // Use popUntil to clear all routes and navigate to LoginPage
      Navigator.of(context).popUntil((route) => false); // Pop all routes
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }

    print('Account and expenditures deleted');
  } catch (e) {
    print('Error deleting account or expenditures: $e');
  }
}

  // Show user's records
  void _viewRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeleteRecords()),
    );
  }

  

  void _viewProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSettingOption(
                'View Profile', Icons.library_books, _viewProfile),
            _buildSettingOption(
                'Change User Name', Icons.person, _changeUserName),
            _buildSettingOption('Change Password', Icons.lock, _changePassword),
            _buildSettingOption(
                'Change Phone Number', Icons.phone, _changePhoneNumber),
            _buildSettingOption('Delete Records', Icons.library_books,
                _viewRecords), // Added View Records
             // Added View Records
            // Added View Records
            _buildSettingOption(
                'Delete Account', Icons.delete_forever, _deleteAccount),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 40),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 40),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, size: 40),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time, size: 40),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 40),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption(String title, IconData icon, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
