import 'package:flutter/material.dart';
import 'home.dart'; // Import HomeScreen for navigation
import 'settings.dart'; // Import SettingsPage (Settings screen)
import 'add.dart';
class SearchViewScreen extends StatefulWidget {
  @override
  _SearchViewScreenState createState() => _SearchViewScreenState();
}

class _SearchViewScreenState extends State<SearchViewScreen> {
  int _selectedIndex = 1; // Start with the Search tab selected.

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Implement the navigation logic for each tab
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        // Stay on Search screen, no navigation needed
        break;
      case 2:
        // Navigate to the Settings page when Settings is tapped
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddPage())
          ); 
        break;
      case 4:
        // Navigate to the Settings page when Settings is tapped
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()), // Navigate to SettingsPage
        );
        break;
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
      ),
      body: Column(
        children: [
          SizedBox(height: 30), // Spacing from top
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOption(
                      icon: Icons.person_search,
                      label: "Vendor",
                      iconSize: 40, // Custom icon size for Vendor
                      iconColor: Colors.blue, // Custom color for Vendor icon
                      labelColor: Colors.blue, // Custom color for Vendor label
                      onTap: () {
                        // Add your onTap functionality here
                      },
                    ),
                    _buildOption(
                      icon: Icons.calendar_today,
                      label: "Date",
                      iconSize: 35, // Custom icon size for Date
                      iconColor: Colors.green, // Custom color for Date icon
                      labelColor: Colors.green, // Custom color for Date label
                      onTap: () {
                        // Add your onTap functionality here
                      },
                    ),
                    _buildOption(
                      icon: Icons.agriculture,
                      label: "Crop",
                      iconSize: 45, // Custom icon size for Crop
                      iconColor: Colors.orange, // Custom color for Crop icon
                      labelColor: Colors.orange, // Custom color for Crop label
                      onTap: () {
                        // Add your onTap functionality here
                      },
                    ),
                  ],
                ),
                SizedBox(height: 50), // Spacing between rows
                GestureDetector(
                  onTap: () {
                    // Add functionality for Sharing Profit button
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 75, // Increased circle size
                        width: 75, // Increased circle size
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: Icon(
                          Icons.handshake_outlined,
                          size: 50,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sharing Profit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 40),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 40, color: Colors.blue),
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

  // Widget to build individual options like Vendor, Date, and Crop
  Widget _buildOption({
    required IconData icon,
    required String label,
    required Function() onTap,
    double iconSize = 30, // Default size for icon
    Color iconColor = Colors.black, // Default color for icon
    Color labelColor = Colors.black, // Default color for label
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 90, // Increased circle size
            width: 90, // Increased circle size
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(45),
            ),
            child: Icon(
              icon,
              size: iconSize, // Dynamically set icon size
              color: iconColor, // Dynamically set icon color
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: labelColor, // Dynamically set label color
            ),
          ),
        ],
      ),
    );
  }
}
